
function whoami(){
    echo 'AWS credentials used:'
    aws sts get-caller-identity
    echo "AWS default region set: ${AWS_DEFAULT_REGION}"
    echo "Docker run as user: $(/usr/bin/whoami)"
}

function configuration_warning(){
    echo "WARNING: missing environment variable $1"
    export SHOW_WARNING=1
}

function token_fromrole(){
    # Copy from original input if exist, else store to original input -- used to renew token
      # AWS_ACCESS_KEY_ID
    if [ ! -z "${_ORIGINAL_AWS_ACCESS_KEY_ID}" ];then
        export AWS_ACCESS_KEY_ID="${_ORIGINAL_AWS_ACCESS_KEY_ID}"
    elif [ ! -z "${AWS_ACCESS_KEY_ID}" ];then
        export _ORIGINAL_AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
    else
        echo 'WARNING: cant retrieve token because AWS_ACESS_KEY_ID is not set'
        return 1
    fi
      # AWS_SECRET_ACCESS_KEY 
    if [ ! -z "${_ORIGINAL_AWS_SECRET_ACCESS_KEY}" ];then
        export AWS_SECRET_ACCESS_KEY="${_ORIGINAL_AWS_SECRET_ACCESS_KEY}"
    elif [ ! -z "${AWS_SECRET_ACCESS_KEY}" ];then
        export _ORIGINAL_AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
    else
        echo 'WARNING: cant retrieve token because AWS_SECRET_ACCESS_KEY is not set'
        return 1
    fi

    # Retrieve fresh (short-term) credentials
    # empy existing token to prevent it will get used
    export AWS_SESSION_TOKEN=
    for line in $( \
        aws sts assume-role \
          --role-arn "$AWS_ROLE_ARN" \
          --role-session-name __auto__ \
        |jq -r  '.Credentials
                 | .["AWS_ACCESS_KEY_ID"] = .AccessKeyId
                 | .["AWS_SECRET_ACCESS_KEY"] = .SecretAccessKey
                 | .["AWS_SESSION_TOKEN" ] = .SessionToken
                 | {AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN}
                 | to_entries
                 | map("\(.key)=\(.value|tostring)") 
                 | .[]' \
    );do
        export ${line}
    done
    return $?
}

[ ! -z "${AWS_ROLE_ARN}" ] && token_fromrole

[ -z "${AWS_DEFAULT_REGION}" ] && export AWS_DEFAULT_REGION='eu-west-1'

if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ];then
    [ -z "${AWS_ACCESS_KEY_ID}" ] && configuration_warning 'AWS_ACCESS_KEY_ID'
    [ -z "${AWS_SECRET_ACCESS_KEY}" ] && configuration_warning 'AWS_SECRET_ACCESS_KEY'
else
    whoami
fi

if [ ! -s ~/.aws/config ];then
    export AWS_PROFILE=local_docker
    mkdir -p ~/.aws
    cat << EOF > ~/.aws/config
[${AWS_PROFILE}]
region=${AWS_DEFAULT_REGION}
EOF
    cat << EOF > ~/.aws/credentials
[${AWS_PROFILE}]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
aws_session_token = ${AWS_SESSION_TOKEN}
EOF
fi
