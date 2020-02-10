 
# AWS Workspace
Docker based Workspace configuration to manage deployments on AWS. This includes environment-setup for most common access-scenario's, the awscli package, and packages closely related and/ or used together in practice. 

Build and run via Makefile. Mounts repository directory from HOST in container runtime on /repo. Default is ~/repositories on HOST (can be changed in Makefile).

Stable points to a directory where packages are version-locked, these are tested
frequently on each (sub-) stack in the following repositories;

- [CloudFormation-Solutions](https://github.com/LINKIT-Group/cloudformation-solutions.git)
- [CloudFormation-Samples](https://github.com/LINKIT-Group/cloudformation-samples.git)

The devel version contains latest packages and experimental add-ons. Devel is primarly for development and testing of build tools. The stable version is recommended for both production pipelines and regular CloudFormation development.

## Quickstart
```
# ensure AWS credentials are in the HOST environment
# change the variables within brackets
export AWS_SECRET_ACCESS_KEY="${YOUR_AWS_SECRET_ACCESS_KEY}"
export AWS_ACCESS_KEY_ID="${YOUR_AWS_ACCESS_KEY_ID}"

# setting (default) region via environment is highly recommended
export AWS_DEFAULT_REGION="${YOUR_AWS_DEFAULT_REGION}"

# option A -- add when security credentials are temporary
# export AWS_SESSION_TOKEN="${YOUR_AWS_SESSION_TOKEN}"

# option B -- add to get new (temporary) credentials via assume-role
# export AWS_ROLE_ARN="${YOUR_AWS_ROLE_ARN}"

# start shell
make shell

# check environment only
make whoami
```

## Build and Version switch
```
# build is only needed to test specific Dockerfile updates
# other make targets auto-build the image if it not yet exists
make build

# by default the Makefile points to "stable" (=symlink to a version-directory, e.g. v1)
# to use a different version, use the Makefile target= option as follows:
make build target=devel
make shell target=devel
```

## CDK quickstart (devel only for now)
```
# bootstrap creates an S3 Bucket to hold deployment artifacts
# this is requirement for any new account
cdk bootstrap

# compare configuration versions
cdk diff

# build, and cleanup the infra stack afterwards
cdk deploy
cdk destroy

# more, check: https://docs.aws.amazon.com/cdk/latest/guide/tools.html
```

