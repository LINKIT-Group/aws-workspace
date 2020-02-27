# --------------------------------------------------------------------
# Copyright (c) 2019 Anthony Potappel - LINKIT, The Netherlands.
# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------

import os
import json
import asyncio


class SubprocessError(Exception):
    """Custom Exception, to raise an unexpected
    response in a function- or api-call"""
    def __init__(self, *args):
        super().__init__(*args)
        if args:
            self.message = args[0]
        else:
            self.message = ''

    def __str__(self):
        return str(self.message)


async def subprocess_reader(output, lines):
    """Parse stdout and stderr output, store each in a list of output lines"""
    while True:
        newline = await output.readline()
        if not newline:
            break
        lines.append(newline.strip().decode())


async def subprocess(command, pathname, stdout_lines, stderr_lines, env, shell=False):
    """Wrap command with async process to capture stdout and stderr separately"""
    if shell is True:
        process = await \
            asyncio.create_subprocess_shell(
                command, env=env, cwd=pathname,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
    else:
        process = await \
            asyncio.create_subprocess_exec(
                *command, env=env, cwd=pathname,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )

    await asyncio.wait([subprocess_reader(process.stdout, stdout_lines),
                        subprocess_reader(process.stderr, stderr_lines)])
    return await process.wait()


def system_call(command, pathname='.', env=None, raise_on_error=True):
    """Execute a system call using asyncio.subprocess, return dict containing:
    exit_code (int), stdout and stderr formatted as list of output-lines
    run as shell when input is a string, else run as subprocess"""
    try:
        if isinstance(command, list):
            if False in [isinstance(item, str) for item in command]:
                raise ValueError
            shell = False
            print_command = ' '.join(
                [os.path.basename(command[0])] \
                + [f'\"{arg}\"' for arg in command[1:]]
            )
        elif isinstance(command, str):
            shell = True
            print_command = command
        else:
            raise ValueError
    except:
        raise ValueError('Input should be a string or a list of strings')

    if not env:
        env = os.environ.copy()

    stdout_lines = []
    stderr_lines = []

    asyncio.set_event_loop(asyncio.new_event_loop())
    event_loop = asyncio.get_event_loop()
    exit_code = event_loop.run_until_complete(subprocess(command,
                                                         pathname,
                                                         stdout_lines,
                                                         stderr_lines,
                                                         env,
                                                         shell=shell))
    event_loop.close()

    response = {
        'command': print_command,
        'path': pathname,
        'exit_code': exit_code,
        'stdout': stdout_lines,
        'stderr': stderr_lines
    }

    if raise_on_error is True and exit_code != 0:
        raise SubprocessError(json.dumps(response, indent=4, default=str))
    return response
