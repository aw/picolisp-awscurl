# picolisp-awscurl - https://github.com/aw/picolisp-awscurl
#
# Copyright (c) 2018-2020 Alexander Williams, Unscramble <license@unscramble.jp>
# License MIT

(setq
  *Aws_method           "GET"
  *Aws_region           "us-east-1"
  *Aws_service          "ec2"
  *Aws_host             "ec2.amazonaws.com"
  *Aws_endpoint         "/"
  *Aws_protocol         "https"
  *Aws_profile          (if (sys "AWS_PROFILE") @ "default")
  *Aws_access_key       (sys "AWS_ACCESS_KEY_ID")
  *Aws_secret_key       (sys "AWS_SECRET_ACCESS_KEY")
  *Aws_session_token    (if (sys "AWS_SESSION_TOKEN") @ (sys "AWS_SECURITY_TOKEN")) # AWS_SECURITY_TOKEN is deprecated
  *Aws_request_date     (dat$ (date T))
  *Aws_request_time     (pack (mapcar '((S) (pad 2 S)) (time (time T)))) )

### native
[de awscurl-native-sha256 (Payload)
  (native "libcrypto.so" "SHA256" '(B . 32) Payload (length Payload) '(NIL (32) ]

[de awscurl-native-hmac (Key Length Payload)
  (let Evp (native "libcrypto.so" "EVP_sha256" 'N)
    (native "libcrypto.so" "HMAC" '(B . 32) Evp Key Length Payload (length Payload) 0 '(NIL (32) ]

# Key = hex string
[de awscurl-native-make-hmac (Key Payload)
  (let (*Key        (chop Key)
        *Iterations (/ (length *Key) 2)
        *P          (native "@" "malloc" 'N *Iterations) ) # allocate some memory to store the key

    (for N *Iterations
      [byte (+ *P (- N 1)) (hex (pack (cut 2 '*Key) ] # store the hex value in a byte
    )
    (byte (+ *P *Iterations 1) 0) # store a null byte
    (let Result (awscurl-list-to-hex (awscurl-native-hmac *P *Iterations Payload))
      (native "@" "free" NIL *P) # free the memory
      Result ]

[de awscurl-parse-native (Payload Key)
  (if Key
      (awscurl-native-make-hmac Key Payload)
      (awscurl-list-to-hex (awscurl-native-sha256 Payload) ]

### main
[de awscurl-make-curl (Cmd)
  (prin (in Cmd (till NIL T) ]

[de awscurl-make-request (Auth Headers)
  (make
    (link 'curl "--silent" "--request" *Aws_method (pack *Aws_protocol "://" *Aws_host *Aws_endpoint (when *Aws_query (pack "?" *Aws_query))) "--header" Auth)
    (mapc '((S) (link "--header" (pack (car S) ": " (cdr S)))) Headers)
    (when *Aws_data     (link "--data" (cdr *Aws_data)))
    (when *Aws_verbose  (link "--verbose"))
    (when *Aws_output   (link "--output" *Aws_output) ]

[de awscurl-make-auth-header (Headers Signature)
   (pack "Authorization: AWS4-HMAC-SHA256 Credential=" *Aws_access_key "/" *Aws_request_date "/" *Aws_region "/" *Aws_service "/aws4_request, SignedHeaders=" (glue ";"  (mapcar car Headers)) ", Signature=" Signature) ]

[de awscurl-list-to-hex (List)
  (lowc (pack (mapcar '((N) (pad 2 (hex N))) List) ]

[de awscurl-string-to-hex (String)
  (awscurl-list-to-hex (mapcar char (chop String) ]

[de awscurl-make-hmac (Key Payload)
  (if *Aws_native
      (awscurl-parse-native Payload Key)
      (awscurl-parse-openssl Payload "-mac" "HMAC" "-macopt" (pack "hexkey:" Key) ]

[de awscurl-make-signature (Str2sign)
  (let (A (awscurl-make-hmac (awscurl-string-to-hex (pack "AWS4" *Aws_secret_key)) *Aws_request_date)
        B (awscurl-make-hmac A *Aws_region)
        C (awscurl-make-hmac B *Aws_service)
        D (awscurl-make-hmac C "aws4_request") )

    (awscurl-make-hmac D Str2sign) ]

[de awscurl-make-canonical-hash (Canonical)
  (pack
    "AWS4-HMAC-SHA256" "^J"
    *Aws_request_date "T" *Aws_request_time "Z" "^J"
    *Aws_request_date "/" *Aws_region "/" *Aws_service "/aws4_request" "^J"
    (if *Aws_native
        (awscurl-parse-native Canonical)
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
      (when *Aws_session_token  (link (cons "x-amz-security-token" *Aws_session_token)))
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
                (case (pack (clip (pop 'L)))
                  # use the values in the config if they weren't set from environment variables
                  ["aws_access_key_id"      (prog1 (clip (pop 'L)) (unless *Aws_access_key     (setq *Aws_access_key     (pack @) ]
                  ["aws_secret_access_key"  (prog1 (clip (pop 'L)) (unless *Aws_secret_key     (setq *Aws_secret_key     (pack @) ]
                  ["aws_session_token"      (prog1 (clip (pop 'L)) (unless *Aws_session_token  (setq *Aws_session_token  (pack @) ]
                  (T (pop 'L) ]

[de awscurl-start ()
  (awscurl-get-credentials)
  (let (Sha256    (if (= "file" (car *Aws_data))
                      (awscurl-file-openssl (cdr *Aws_data))
                      (if *Aws_native
                          (awscurl-parse-native (cdr *Aws_data))
                          (awscurl-parse-openssl (cdr *Aws_data)) ) )
        Headers   (awscurl-sort-headers Sha256)
        Canonical (awscurl-make-canonical Sha256 Headers)
        Str2sign  (awscurl-make-canonical-hash Canonical)
        Signature (awscurl-make-signature Str2sign)
        Auth      (awscurl-make-auth-header Headers Signature) )

    (awscurl-make-curl (awscurl-make-request Auth Headers)) ]

[de awscurl-data (Value)
  (let Data (chop Value)
    (setq *Aws_data
      (if (and (= (char 64) (car Data)) (info (pack (cdr Data))))
          (cons "file" (pack (cdr Data)))
          (cons "data" Value) ]

[de awscurl-headers (Key Value)
  (push '*Aws_headers (cons (lowc Key) (pack (clip (chop Value) ]

### helpers
[de tc-call-msg (Cmd Msg)
  (pipe (out Cmd (prin Msg)) (line) ]
