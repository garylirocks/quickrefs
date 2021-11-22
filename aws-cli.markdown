# AWS CLI

## Configure

```sh
# config the 'default' profile: credentials, default region and output format
aws configure

# config the 'work' profile
aws configure --profile work

# set default region for current profile
aws configure set default.region ap-southeast-2
```

Config files are in `~/.aws/`, there are two files: `credentials`, `config`

Example:

- `credentials`:

    ```
    [default]
    aws_secret_access_key = ****
    aws_access_key_id = ****

    [work]
    aws_secret_access_key = ****
    aws_access_key_id = ****
    ```

- `config`:

    ```
    [default]
    region = ap-southeast-2

    [profile work]
    region = ap-southeast-1
    ```

There are two profiles in this example, you can switch between profiles by setting an environment variable:

```sh
export AWS_PROFILE=work
```

or for one-off usage, add a `--profile` parameter to any command:

```sh
aws s3 ls --profile=work
```

## S3

```sh
# create a bucket
aws s3 mb s3://testing-12345

# upload a file
aws s3 cp x.tar s3://testing-12345/x.tar
```

## KMS

```sh
# create a key and get the id
keyId=$(aws kms create-key --query KeyMetadata.Arn --output text)

# assign a alias to the key
aws kms create-alias \
    --alias-name alias/myKey \
    --target-key-id $keyId
```