#!/usr/bin/env pil

[de APP_INFO
  ("name"      "awscurl")
  ("version"   "0.9.0")
  ("summary"   "PicoLisp AWS CLI tool using OpenSSL and Curl")
  ("source"    "https://github.com/aw/picolisp-awscurl")
  ("author"    "Alexander Williams")
  ("license"   "MIT")
  ("copyright" "(c) 2018-2020 Alexander Williams, Unscramble <license@unscramble.jp>") ]

[de APP_HELP
  ("usage"     "./awscurl.l [options]")
  ("example"   "./awscurl.l --service s3 --host awscurl.s3.amazonaws.com --endpoint /mybucket --query 'a=Prefix&b=Marker'^J")
  ("options"   ("--help"                  "Show this help message and exit")
               ()
               ("--data <data>"           "HTTP POST data (default: None)")
               ("--endpoint <endpoint>"   "The API endpoint of the AWS service (default: /)")
               ("--header <key> <value>"  "HTTP header data (default: None)")
               ("--host <host>"           "The Host of the AWS service (default: ec2.amazonaws.com)")
               ("--output <file>"         "Filename where data should be output (default: STDOUT)")
               ("--protocol http|https"   "Protocol for talking to AWS (default: https)")
               ("--query <query>"         "The Query parameters of the AWS service (default: None)")
               ("--region <region>"       "AWS region (default: us-east-1)")
               ("--request <method>"      "Specify request method to use (default: GET)")
               ("--service <service>"     "AWS service (default: ec2)")
               ("--verbose"               "Verbose flag (default: False)")
               ()
               ("Environment variables: AWS_PROFILE, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN/AWS_SECURITY_TOKEN^J  Reads ~/.aws/credentials if an environment variable isn't set." ]

(load (pack (car (file)) "libawscurl.l"))

### helpers
[de tc-options (N)
  (tab  (2 -22 5) " " (car N) (cdr N) ]

[de tc-show-help ()
  (prinl
    (cdr (assoc "name" APP_INFO)) " v" (cdr (assoc "version" APP_INFO)) "^J"
    "Copyright " (cdr (assoc "copyright" APP_INFO)) "^J"
    "License " (cdr (assoc "license" APP_INFO)) "^J^J"
    (cdr (assoc "summary" APP_INFO)) "^J"
    (cdr (assoc "source" APP_INFO)) "^J^J"
    (tc-options (list "Usage:" (cdr (assoc "usage" APP_HELP)))) "^J"
    (tc-options (list "Example:" (cdr (assoc "example" APP_HELP))))
    (tc-options (list "Options:"))
    (mapcar tc-options (cdr (assoc "options" APP_HELP))) ]

### start
(ifn  (argv)
      (tc-show-help)
      (while (opt)
        (case @
          (--verbose  (on *Aws_verbose))
          (--request  (setq *Aws_method   (opt)))
          (--data     (awscurl-data       (opt)))
          (--header   (awscurl-headers    (opt) (opt)))
          (--region   (setq *Aws_region   (opt)))
          (--service  (setq *Aws_service  (opt)))
          (--host     (setq *Aws_host     (opt)))
          (--endpoint (setq *Aws_endpoint (opt)))
          (--query    (setq *Aws_query    (opt)))
          (--protocol (setq *Aws_protocol (opt)))
          (--output   (setq *Aws_output   (opt)))
          (T          (tc-show-help) (bye 1)) ) )
      (awscurl-start) )

(bye)
