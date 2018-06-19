#!/usr/bin/env pil

[de APP_INFO
  ("name"      "awscurl")
  ("version"   "0.6.1")
  ("summary"   "PicoLisp AWS CLI tool using OpenSSL and Curl")
  ("source"    "https://github.com/aw/picolisp-awscurl")
  ("author"    "Alexander Williams")
  ("license"   "MIT")
  ("copyright" "(c) 2018 Alexander Williams, Unscramble <license@unscramble.jp>") ]

[de APP_HELP
  ("usage"     "./awscurl.l [options]")
  ("example"   "./awscurl.l --service s3 --host awscurl.s3.amazonaws.com --endpoint /mybucket --query 'a=Prefix&b=Marker'^J")
  ("options"   ("--help"                  "Show this help message and exit")
               ()
               ("--data <data>"           "HTTP POST data (default: None)")
               ("--endpoint <endpoint>"   "The API endpoint of the AWS service (default: /)")
               ("--header <key> <value>"  "HTTP header data (default: None)")
               ("--host <host>"           "The Host of the AWS service (default: ec2.amazonaws.com)")
               ("--query <query>"         "The Query parameters of the AWS service (default: None)")
               ("--region <region>"       "AWS region (default: us-east-2)")
               ("--request <method>"      "Specify request method to use (default: GET)")
               ("--service <service>"     "AWS service (default: ec2)")
               ("--verbose"               "Verbose flag (default: False)")
               ()
               ("Environment variables: AWS_PROFILE, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN/AWS_SECURITY_TOKEN^J  Reads ~/.aws/credentials if an environment variable isn't set." ]

(setq
  *Aws_method           "GET"
  *Aws_region           "us-east-2"
  *Aws_service          "ec2"
  *Aws_host             "ec2.amazonaws.com"
  *Aws_endpoint         "/"
  *Aws_profile          (if (sys "AWS_PROFILE") @ "default")
  *Aws_access_key       (sys "AWS_ACCESS_KEY_ID")
  *Aws_secret_key       (sys "AWS_SECRET_ACCESS_KEY")
  *Aws_session_token    (if (sys "AWS_SESSION_TOKEN") @ (sys "AWS_SECURITY_TOKEN")) # AWS_SECURITY_TOKEN is deprecated
  *Aws_request_date     (dat$ (date T))
  *Aws_request_time     (pack (mapcar '((S) (pad 2 S)) (time (time T)))) )

### main
[de awscurl-make-curl (Cmd)
  (prin (in Cmd (till NIL T) ]

[de awscurl-make-request (Auth Headers)
  (make
    (link 'curl "--silent" "--request" *Aws_method (pack "https://" *Aws_host *Aws_endpoint (when *Aws_query (pack "?" @))) "--header" Auth)
    (mapc '((S) (link "--header" (pack (car S) ": " (cdr S)))) Headers)
    (when *Aws_data     (link "--data" (cdr *Aws_data)))
    (when *Aws_verbose  (link "--verbose") ]

[de awscurl-make-auth-header (Headers Signature)
   (pack "Authorization: AWS4-HMAC-SHA256 Credential=" *Aws_access_key "/" *Aws_request_date "/" *Aws_region "/" *Aws_service "/aws4_request, SignedHeaders=" (glue ";"  (mapcar car Headers)) ", Signature=" Signature) ]

[de awscurl-make-hmac (Key Payload)
  (awscurl-parse-openssl Payload "-mac" "HMAC" "-macopt" Key) ]

[de awscurl-make-signature (Str2sign)
  (let (A (awscurl-make-hmac (pack "key:AWS4" *Aws_secret_key) *Aws_request_date)
        B (awscurl-make-hmac (pack "hexkey:" A) *Aws_region)
        C (awscurl-make-hmac (pack "hexkey:" B) *Aws_service)
        D (awscurl-make-hmac (pack "hexkey:" C) "aws4_request") )

    (awscurl-make-hmac (pack "hexkey:" D) Str2sign) ]

[de awscurl-make-canonical-hash (Canonical)
  (pack
    "AWS4-HMAC-SHA256" "^J"
    *Aws_request_date "T" *Aws_request_time "Z" "^J"
    *Aws_request_date "/" *Aws_region "/" *Aws_service "/aws4_request" "^J"
    (awscurl-parse-openssl Canonical) ]

[de awscurl-make-canonical (Hash Headers)
  (pack
    *Aws_method "^J"
    *Aws_endpoint "^J"
    *Aws_query "^J"
    (mapcar '((S) (pack (car S) ":" (cdr S) "^J")) Headers) "^J"
    (glue ";"  (mapcar car Headers)) "^J"
    Hash ]

[de awscurl-sort-headers (Sha256)
  (by car sort
    (make
      (link
        (cons "host" *Aws_host)
        (cons "x-amz-content-sha256" Sha256)
        (cons "x-amz-date" (pack *Aws_request_date "T" *Aws_request_time "Z")) )
      (when *Aws_data           (link (cons "content-length" (if (= "file" (car *Aws_data)) (car (info (cdr *Aws_data))) (length (cdr *Aws_data))))))
      (when *Aws_session_token  (link (cons "x-amz-security-token" @)))
      (mapc link *Aws_headers) ]

[de awscurl-file-openssl (Filename)
  (pack (clip (cadr (split (in (make (link 'openssl "dgst" "-sha256" Filename)) (line)) "=") ]

[de awscurl-parse-openssl (Payload . @)
  (pack (clip (cadr (split (tc-call-msg (make (link 'openssl "dgst" "-sha256") (when (rest) (chain @))) Payload) "=") ]

[de awscurl-get-credentials ()
  (let Credentials (pack (sys "HOME") "/.aws/credentials") # ~/.aws/credentials
    (when (info Credentials)
          (in Credentials (while (and (from (pack "[" *Aws_profile "]")) (till "["))
            (let Keys (clip (split @ "^J" "=")) # remove newlines and split into key=value pairs
              (for (L Keys L)
                (case (pack (clip (++ L)))
                  # use the values in the config if they weren't set from environment variables
                  ["aws_access_key_id"      (prog1 (clip (++ L)) (unless *Aws_access_key     (setq *Aws_access_key     (pack @) ]
                  ["aws_secret_access_key"  (prog1 (clip (++ L)) (unless *Aws_secret_key     (setq *Aws_secret_key     (pack @) ]
                  ["aws_session_token"      (prog1 (clip (++ L)) (unless *Aws_session_token  (setq *Aws_session_token  (pack @) ]
                  (T (++ L) ]

[de awscurl-start ()
  (awscurl-get-credentials)
  (let (Sha256    (if (= "file" (car *Aws_data)) (awscurl-file-openssl (cdr *Aws_data)) (awscurl-parse-openssl (cdr *Aws_data)))
        Headers   (awscurl-sort-headers Sha256)
        Canonical (awscurl-make-canonical Sha256 Headers)
        Str2sign  (awscurl-make-canonical-hash Canonical)
        Signature (awscurl-make-signature Str2sign)
        Auth      (awscurl-make-auth-header Headers Signature) )

    (awscurl-make-curl (awscurl-make-request Auth Headers)) ]

[de awscurl-data (Value)
  (let Data (chop Value)
    (setq *Aws_data
      (if (and (= "@" (car Data)) (info (pack (cdr Data))))
          (cons "file" (pack (cdr Data)))
          (cons "data" Value) ]

[de awscurl-headers (Key Value)
  (push '*Aws_headers (cons (lowc Key) (pack (clip (chop Value) ]

### helpers
[de tc-call-msg (Cmd Msg)
  (pipe (out Cmd (prin Msg)) (line) ]

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
          (T          (tc-show-help) (bye 1)) ) )
      (awscurl-start) )

(bye)
