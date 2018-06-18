# Use Curl and OpenSSL to sign and make AWS requests

This command line tool can be used to sign [AWS Signature Version 4](https://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html) requests and make calls to various AWS APIs.

  1. [Requirements](#requirements)
  2. [Usage](#usage)
  3. [Options](#options)
  4. [Contributing](#contributing)
  5. [Thanks](#thanks)
  6. [Why](#why)
  7. [License](#license)

# Requirements

  * PicoLisp 32-bit or 64-bit v3.1.11+
  * Tested up to PicoLisp v18.6.5
  * `openssl v1.0.0+`: for signing and hashing strings
  * `curl`: for sending requests to the AWS APIs

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
./awscurl.l --service s3 --host awscurl-sample-bucket.s3.amazonaws.com --region us-east-1
```

  * Call EC2:

```
./awscurl.l --service ec2 --host ec2.amazonaws.com --query 'Action=DescribeRegions&Version=2013-10-15'
```

  * Call API Gateway:

```
./awscurl.l --service execute-api --data '{"test":"json"}' --host '<prefix>.execute-api.us-east-1.amazonaws.com' --endpoint '/<resource>'
```

# Options

```
Usage:		./awscurl.l [options]

Options:
  --help              Show this help message and exit

  --data <data>       HTTP POST data (default: None)
  --endpoint <endpoint>     The API endpoint of the AWS service (default: /)
  --header <key> <value>    HTTP header data (default: None)
  --host <host>       The Host of the AWS service (default: ec2.amazonaws.com)
  --query <query>     The Query parameters of the AWS service (default: None)
  --region <region>     AWS region (default: us-east-2)
  --request <method>      Specify request method to use (default: GET)
  --service <service>     AWS service (default: ec2)
  --verbose       Verbose flag (default: False)
```

# Contributing

If you find any bugs or issues, please [create an issue](https://github.com/aw/picolisp-awscurl/issues/new).

If you want to improve this tool, please make a pull-request.

# Thanks

  * This tool was heavily inspired by [Python awscurl](https://github.com/okigan/awscurl)
  * Thanks to [Łukasz Adamczak](http://czak.pl/2015/09/15/s3-rest-api-with-curl.html) for the wonderful article explaining the intricacies of _AWS Signature Version 4_ with simple curl/openssl/bash

# Why

**Q:** Why not use `awscli`, `boto`, `awscurl`, `Ansible`, `Packer`, or one of many other available AWS SDKs?

**A:** Size. It seems every single tool in existence is incredibly bloated and contains too many dependencies, too many features, and too much complexity. I really just wanted to make a handful of `EC2` calls from the command-line. This tool is slightly more flexible than what I needed, but it works _without_ any external dependencies other than what's already deployed on most Linux systems. For comparison, `Python awscurl` and its dependencies are `~18MB`, whereas this `PicoLisp awscurl` is `~6KB` on disk.

# License

[MIT License](LICENSE)

Copyright (c) 2018 Alexander Williams, Unscramble <license@unscramble.jp>
