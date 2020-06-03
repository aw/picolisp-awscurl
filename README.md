# PicoLisp AWS CLI tool using OpenSSL and Curl

This command line tool can be used to sign [AWS Signature Version 4](https://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html) requests and make calls to various AWS APIs.

[![GitHub release](https://img.shields.io/github/release/aw/picolisp-awscurl.svg)](https://github.com/aw/picolisp-awscurl) [![Dependency](https://img.shields.io/badge/[deps]&#32;picolisp--unit-v3.0.0-ff69b4.svg)](https://github.com/aw/picolisp-unit.git) ![Build status](https://github.com/aw/picolisp-awscurl/workflows/CI/badge.svg?branch=master)

  1. [Requirements](#requirements)
  2. [Usage](#usage)
  3. [Options](#options)
  4. [Contributing](#contributing)
  5. [Thanks](#thanks)
  6. [Why](#why)
  7. [License](#license)

# Requirements

  * `picolisp`: 32-bit or 64-bit `v3.1.11+`, tested up to PicoLisp `v20.5.26`, [see test runs](https://github.com/aw/picolisp-awscurl/actions/)
  * `picolisp-unit`: `v3.0.0+` for testing the library
  * `openssl`: `v1.0.0+` for signing and hashing strings
  * `curl`: for sending requests to the AWS APIs

### Notes

The file `libawscurl.l` can be included as a library, rather than using the command line `awscurl.l`. Function are prefixed with `awscurl-` and variables are prefixed with `*Aws_`.

# Usage

## WARNING

There is currently **no validation** on command line arguments. Be careful the input you provide. [See issue #1](https://github.com/aw/picolisp-awscurl/issues/1)

### Environment variables

The following environment variables are used:

  * `AWS_PROFILE`: Default: `default`
  * `AWS_ACCESS_KEY_ID`
  * `AWS_SECRET_ACCESS_KEY`
  * `AWS_SESSION_TOKEN` or `AWS_SECURITY_TOKEN` (deprecated)

If any of those environment variables are not set, the values will be read from `$HOME/.aws/credentials` using the `[default]` or `$AWS_PROFILE` profile.

### Examples

  * Call S3: List bucket content

```
./awscurl.l --service s3 --data @myfile.json --header 'content-type' 'application/json' --host awscurl-sample-bucket.s3.amazonaws.com --region us-east-1
# NOTE: for files > 1KB, disable Expect header with: --header Expect ""
```

  * Call EC2 (DescribeRegions):

```
./awscurl.l --query 'Action=DescribeRegions&Version=2013-10-15'
```

  * Call EC2 (ImportKeyPair):
```
./awscurl.l --service ec2 --region ap-northeast-1 --host ap-northeast-1.ec2.amazonaws.com --query 'Action=ImportKeyPair&KeyName=my-key&Version=2016-11-15' --request POST --data 'PublicKeyMaterial=c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFCQVFDMkxIRitwY1g3ZmRtVWZRMm53TUt5ZmQ5ZktFQWVaY2dOblB5UDhCdmZnTGtSREZsZjV5ODR5Q09UbWdlS05Fd2Y1Ujhoei9ySmNwVEpNcURNS0pnS29qWVp5bWNTYzhROFpsY3lQdm5BYXZ5UEJVdUZYbUZMRDlpckNBcXREK3cxSEFpaVNlZyszdXN1VC9Vc1NKNWNOU3g4em5lSVhmMW9aSzJHQmswck90cEtwVy94c3gyNnNtUWNQWkxCMVYxSVc5NmRkbm1kUTNtQU1RNndPVUtSMytwckRWN2dhc2xOUjVTdkdaZnFreGpaUHNXcFNGRFlqN3I3WkU5MjB3YjIrT1RHQ1NIa21maUlDNVI3REdrUEc3emhEbk1yMHVlb3Qra1JRNjE4bklvQTVDeFhiaHdJalFYVTRFYjl3YVZsaXhmeGpmY1hjZGcwSEMyRnc5SHAgYWxleAo='
```

  * Call API Gateway:

```
./awscurl.l --service execute-api --data '{"test":"json"}' --host '<prefix>.execute-api.us-east-1.amazonaws.com' --endpoint '/<resource>'
```

# Options

```
Usage:		./awscurl.l [options]

Options:
  --help                    Show this help message and exit

  --data <data>             HTTP POST data (default: None)
  --endpoint <endpoint>     The API endpoint of the AWS service (default: /)
  --header <key> <value>    HTTP header data (default: None)
  --host <host>             The Host of the AWS service (default: ec2.amazonaws.com)
  --protocol http|https     Protocol for talking to AWS (default: https)
  --query <query>           The Query parameters of the AWS service (default: None)
  --region <region>         AWS region (default: us-east-1)
  --request <method>        Specify request method to use (default: GET)
  --service <service>       AWS service (default: ec2)
  --verbose                 Verbose flag (default: False)
```

# Contributing

If you find any bugs or issues, please [create an issue](https://github.com/aw/picolisp-awscurl/issues/new).

If you want to improve this tool, please make a pull-request.

# Thanks

  * This tool was heavily inspired by [Python awscurl](https://github.com/okigan/awscurl)
  * Thanks to [Łukasz Adamczak](http://czak.pl/2015/09/15/s3-rest-api-with-curl.html) for the wonderful article explaining the intricacies of _AWS Signature Version 4_ with simple curl/openssl/bash

# Why

**Q:** Why not use `awscli`, `boto`, `awscurl`, `Ansible`, `Packer`, or one of many other available AWS SDKs?

**A:** Size. It seems every single tool in existence is incredibly bloated and contains too many dependencies, too many features, and too much complexity. I really just wanted to make a handful of `EC2` calls from the command-line. This tool is slightly more flexible than what I needed, but it works _without_ any external dependencies other than what's already deployed on most Linux systems. For comparison, `Python awscurl` and its dependencies are `~18MB`, whereas this `PicoLisp awscurl` is `~8KB` on disk.

# License

[MIT License](LICENSE)

Copyright (c) 2018-2020 Alexander Williams, Unscramble <license@unscramble.jp>
