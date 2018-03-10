AWS CLI notes
=============

## Configure

default config files are in `~/.aws/`, there are two files: `credentials`, `config`

example:

`credentials`:

    [default]
    aws_secret_access_key = ****
    aws_access_key_id = ****

    [work]
    aws_secret_access_key = ****
    aws_access_key_id = ****

`config`:

    [default]
    region = ap-southeast-2

    [profile work]
    region = ap-southeast-1

there are two profiles in this example, you can switch between profiles by setting an environment variable:

    export AWS_PROFILE=work

or for one-off usage, add a `--profile` parameter to any command:

    aws s3 ls --profile=work




