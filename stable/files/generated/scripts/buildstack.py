
import os
import sys
import re
import stat
import json
import logging
import argparse

from shutil import copytree
from system_execute import system_call


logger = logging.getLogger()
logger.setLevel(logging.INFO)

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
logger.addHandler(handler)


is_newer = lambda a, b: int(os.stat(a).st_mtime) > int(os.stat(b).st_mtime)
join_skip_empty = lambda a, b: '/'.join([a, b]) if a else b


def trim_string_alphanum(name, default='', length=None):
    """Replace non alphanum chars with '-',
    remove leading, trailing and double '-' chars, trim length"""
    newstr = re.sub(
        '^-|-$', '', re.sub('[-]+', '-', re.sub('[^-a-zA-Z0-9]', '-', name[0:length]))
    )
    if not newstr:
        return default
    return newstr


def cleanup_dir_safe(realpath, skip_root_hidden=False):
    """Cleanup directory. The '_safe' stands for executing an additional regex
    verification on path -- better redundant than sorry"""
    if not re.match('^/?[-a-zA-Z0-9_.]{1,}/[-a-zA-Z0-9_/.]{1,}$', realpath):
        raise Exception('builddir pattern must match: \'^/?[-a-zA-Z0-9_.]{1,}/[-a-zA-Z0-9_/.]{1,}$\'')

    # use shell to enable expansion for '/*'
    shell_command = f'rm -rf \'{realpath}\''
    if skip_root_hidden is True:
        shell_command = shell_command + '/*'
    response = system_call(shell_command, raise_on_error=True)
    logger.info(f'run: {response["command"]}')


def build_packages(build_path, python_path, overlay_path, python_command):
    package_path = '/'.join([overlay_path, python_path])
    requirements_in = '/'.join([build_path, python_path, 'requirements.in'])
    requirements_out = '/'.join([build_path, python_path, 'requirements.txt'])
    requirements_installed = '/'.join([package_path, 'requirements.txt'])

    if not os.path.isdir(package_path):
        os.makedirs(package_path)
    else:
        try:
            if not is_newer(requirements_in, requirements_installed):
                logger.info(f'pip packages up-to-date: {python_path}')
                return
        except Exception:
            pass
        logger.info(f'pip packages require update: {python_path}')
        cleanup_dir_safe(package_path)

    # even though both piptools and pip are python
    # recommended practice is to run via syscall

    # create requirements.txt
    response = system_call(
        [sys.executable, '-m', 'piptools', 'compile', requirements_in,
         '--output-file', requirements_out],
        raise_on_error=True
    )
    logger.info('\n'.join([f'run: {response["command"]}'] + response['stderr']))

    # install packages
    #   don't use sys.executable here because we want the venv-version
    response = system_call(
        [python_command, '-m', 'pip', 'install', '--upgrade',
         '-r', requirements_out, '-t', package_path],
        raise_on_error=True
    )
    logger.info('\n'.join([f'run: {response["command"]}'] + response['stdout']))

    # check package integrity
    response = system_call(
        [python_command, '-m', 'pip', 'check'],
        pathname=package_path,
        env=dict(os.environ, PYTHONPATH='.'),
        raise_on_error=True
    )
    logger.info('\n'.join([f'run: {response["command"]}'] + response['stdout']))

    # after successful install, link latest requirements.txt to package-dir
    # this file is used to check if updates are required in a next round
    hardcopy(requirements_out, requirements_installed)


def sync_tobuild(stackdir, builddir):
    """Synchronise a source to builddir: first scrub builddir, than (re-)link files
    because hardlinks are used this is extremely fast"""
    if not os.path.isdir(stackdir):
        raise ValueError(f'stackdir does not exist: \'{stackdir}\'')
    if not os.path.isdir(builddir):
        os.makedirs(builddir)

    # cleanup builddir:
    #   skip hidden directories (e.g. .pip-overlay) on root level
    #   revert to safe cleanup function for additional path validation
    cleanup_dir_safe(builddir, skip_root_hidden=True)

    # fastcopy (hardlink) source in to (disposable) builddir
    #   apply system-call for performance, and easyness to skip hidden on root-level
    #   use shell to enable expansion for '*'
    response = system_call(
        f'cp -alf \'{stackdir}\'/* \'{builddir}\'',
        raise_on_error=True
    )
    logger.info(f'run: {response["command"]}')


def find_regfiles_recursive(realpath='.', rootpath='', pattern=''):
    """Find files matching pattern, return relative paths"""
    files = {
        name: os.lstat('/'.join([realpath, name]))
        for name in os.listdir(realpath) if name[0] != '.'
    }

    matches = []
    for name, st in files.items():
        if stat.S_ISREG(st.st_mode):
            if name == pattern:
                matches.append(join_skip_empty(rootpath, name))
        elif stat.S_ISDIR(st.st_mode):
            matches = matches + \
                find_regfiles_recursive(
                    realpath='/'.join([realpath, name]),
                    rootpath=join_skip_empty(rootpath, name),
                    pattern=pattern
                )
    return matches


def hardcopy(srcobj, dstname):
    """Create a hardlink. Skip if destination is the same file as source,
    force link if destination is a different file by removing it first"""
    try:
        dstname_info = os.lstat(dstname)
        if dstname_info.st_ino == os.lstat(srcobj).st_ino:
            # same file
            return
        # different file
        os.unlink(dstname)
    except Exception:
        # assume no destination file is present
        # if assumption is wrong, next link call will fail-exit just as well
        pass
    os.link(srcobj, dstname)


def buildstack(stackdir, builddir):
    """Synchronise stackdir to build, than for each python-package
    pull dependency packages to local"""
    sync_tobuild(stackdir, builddir)

    matches = find_regfiles_recursive(
        realpath=builddir,
        rootpath='',
        pattern='requirements.in'
    )

    if matches:
        overlay_path = '/'.join([builddir, '.pip-overlay'])

        # create venv and location of python within it, calling it from here provides
        # a clean python context, to build the correct set of packages per app
        python_command = '/'.join([builddir, '.venv/bin/python'])
        if not os.path.isfile(python_command):
            response = system_call(
                ['virtualenv', '/'.join([builddir, '.venv'])],
                raise_on_error=True
            )
            logger.info('\n'.join([f'run: {response["command"]}'] + response['stdout']))

        # install packages for each app
        #   wish-list -- this can easily be parallelised
        for match in matches:
            build_packages(
                builddir,
                '/'.join(match.split('/')[:-1]),
                overlay_path,
                python_command
            )

        # merge overlay_path
        copytree(overlay_path, builddir, copy_function=hardcopy, dirs_exist_ok=True)


def main(name=None):
    """Main routine: parse --stackdir and --builddir arguments,
     and call buildstack(STACKDIR, BUILDDIR)"""
    module_name = __loader__.name.split('.')[0]
    parser = argparse.ArgumentParser(
        prog=module_name,
        description='Builds ready-to-deploy Python based serverless stacks'
    )

    parser.add_argument('--stackdir', action='store', required=True, type=str,
                        help='Stack Directory (source)')
    parser.add_argument('--builddir', action='store', required=False, type=str,
                        help='Build Directory (target); \
                              defaults=.build/$(basename ${STACKDIR})')

    args = parser.parse_args(sys.argv[1:])

    if not os.path.isdir(args.stackdir):
        raise ValueError(f'not a directory: \'{args.stackdir}\'')

    if not args.builddir:
        args.builddir = f"{os.environ.get('BUILD_ROOTDIR', '.build')}/stack-" \
            + trim_string_alphanum(os.path.basename(args.stackdir), default='local')

    if not re.match('^/?[-a-zA-Z0-9_.]{1,}/[-a-zA-Z0-9_/.]{1,}$', args.builddir):
        raise Exception('builddir pattern must match: \'^/?[-a-zA-Z0-9_.]{1,}/[-a-zA-Z0-9_/.]{1,}$\'')

    buildstack(args.stackdir, args.builddir)
    return 0


if __name__ == '__main__':
    sys.exit(main())
