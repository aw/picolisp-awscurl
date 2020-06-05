#!/usr/bin/env pil

(load (pack (car (file)) ".modules/picolisp-unit/HEAD/unit.l"))

(load (pack (car (file)) "libawscurl.l"))

# Requests are time-dependent
(setq
  *Aws_request_date "20180713"
  *Aws_request_time "052018" )

(when (= "native" (opt)) (on *Aws_native))

# Default HOME to 'test' dir
(sys "HOME" "test")

(prinl "^J  PicoLisp AWS CLI tool using OpenSSL and Curl^J")

[de test-headers-normalized ()
  (use *Aws_headers
    (awscurl-headers "Content-Type" "application/json")
    (assert-equal   '(("content-type" . "application/json")) *Aws_headers "Ensure headers are normalized (Content-Type)")
    (off *Aws_headers)
    (awscurl-headers "Accept" "")
    (assert-equal   '(("accept")) *Aws_headers "Ensure headers are normalized (Accept)") ]

[de test-data-read ()
  (use *Aws_data
    (awscurl-data "{\"json\":\"data\"}")
    (assert-equal   '("data" . "{\"json\":\"data\"}") *Aws_data "Ensure the data is read correctly: (string)")
    (off *Aws_data)
    (awscurl-data "@test/data.json")
    (assert-equal   '("file" . "test/data.json") *Aws_data "Ensure the data is read correctly: (file)")
  ]

[de test-get-credentials ()
  (use (*Aws_profile *Aws_access_key *Aws_secret_key *Aws_session_token)
    (awscurl-get-credentials)
    (assert-equal   "test-access-key" *Aws_access_key "Should read access key from [default] credentials file")
    (assert-equal   "test-secret-key" *Aws_secret_key "Should read secret key from [default] credentials file")
    (assert-equal   "test-session-token" *Aws_session_token "Should read session token from [default] credentials file")
    (setq *Aws_profile "awscurl")
    (off *Aws_access_key *Aws_secret_key)
    (awscurl-get-credentials)
    (assert-equal   "awscurl-access-key" *Aws_access_key "Should read access key from [awscurl] credentials file")
    (assert-equal   "awscurl-secret-key" *Aws_secret_key "Should read secret key from [awscurl] credentials file")
    (assert-equal   "test-session-token" *Aws_session_token "Should read session token from *Aws_session_token variable")
  ]

[de test-sort-headers ()
  (use (*Aws_data *Aws_session_token *Aws_headers)
    (assert-equal '(("host" . "ec2.amazonaws.com") ("x-amz-content-sha256" . "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6") ("x-amz-date" . "20180713T052018Z")) (awscurl-sort-headers "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6") "Ensure headers are sorted correctly (default)")
    (awscurl-data "{\"json\":\"data\"}")
    (assert-equal '(("content-length" . 15) ("host" . "ec2.amazonaws.com") ("x-amz-content-sha256" . "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6") ("x-amz-date" . "20180713T052018Z")) (awscurl-sort-headers "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6") "Ensure headers are sorted correctly (data)")
    (sys "HOME" "test")
    (awscurl-get-credentials)
    (assert-equal '(("content-length" . 15) ("host" . "ec2.amazonaws.com") ("x-amz-content-sha256" . "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6") ("x-amz-date" . "20180713T052018Z") ("x-amz-security-token" . "test-session-token")) (awscurl-sort-headers "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6") "Ensure headers are sorted correctly (data+token)")
    (awscurl-headers "Content-Type" "application/json")
    (assert-equal '(("content-length" . 15) ("content-type" . "application/json") ("host" . "ec2.amazonaws.com") ("x-amz-content-sha256" . "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6") ("x-amz-date" . "20180713T052018Z") ("x-amz-security-token" . "test-session-token")) (awscurl-sort-headers "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6") "Ensure headers are sorted correctly (data+token+headers)")
  ]

[de test-make-canonical ()
  (use (*Aws_access_key *Aws_secret_key *Aws_session_token)
    (awscurl-get-credentials)
    (let (Canonical (awscurl-make-canonical "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6" (awscurl-sort-headers "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6"))
          Hash      (awscurl-make-canonical-hash Canonical)
          Signature (awscurl-make-signature Hash)
          Auth      (awscurl-make-auth-header (awscurl-sort-headers "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6") Signature) )
    (assert-equal "GET^J/^J^Jhost:ec2.amazonaws.com^Jx-amz-content-sha256:9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6^Jx-amz-date:20180713T052018Z^Jx-amz-security-token:test-session-token^J^Jhost;x-amz-content-sha256;x-amz-date;x-amz-security-token^J9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6" Canonical "Ensure canonical string is created")
    (assert-equal "AWS4-HMAC-SHA256^J20180713T052018Z^J20180713/us-east-1/ec2/aws4_request^J38a3692e616a95f3c6eb1877d0417eb878e9298fd6ee64922ecfb6b99dbfdd3f" Hash "Ensure canonical hash is created")
    (assert-equal "1213f26a4a5e9487408efe6f6fe68c4a89a09b05efcbbc29308ad1e754f69755" Signature "Ensure canonical signature is created")
    (assert-equal "Authorization: AWS4-HMAC-SHA256 Credential=test-access-key/20180713/us-east-1/ec2/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=1213f26a4a5e9487408efe6f6fe68c4a89a09b05efcbbc29308ad1e754f69755" Auth "Ensure canonical auth header is created")
    (assert-equal '(curl "--silent" "--request" "GET" "https://ec2.amazonaws.com/" "--header" "Authorization: AWS4-HMAC-SHA256 Credential=test-access-key/20180713/us-east-1/ec2/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=1213f26a4a5e9487408efe6f6fe68c4a89a09b05efcbbc29308ad1e754f69755" "--header" "host: ec2.amazonaws.com" "--header" "x-amz-content-sha256: 9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6" "--header" "x-amz-date: 20180713T052018Z" "--header" "x-amz-security-token: test-session-token") (awscurl-make-request Auth (awscurl-sort-headers "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6")) "Ensure canonical request is created") ]

[de test-make-canonical-data ()
  (use (*Aws_access_key *Aws_secret_key *Aws_session_token *Aws_query *Aws_data *Aws_verbose)
    (awscurl-get-credentials)
    (setq *Aws_query "Action=ImportKeyPair&KeyName=my-key")
    (awscurl-data "{\"json\":\"data\"}")
    (on *Aws_verbose)
    (let (Canonical (awscurl-make-canonical "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6" (awscurl-sort-headers "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6"))
          Hash      (awscurl-make-canonical-hash Canonical)
          Signature (awscurl-make-signature Hash)
          Auth      (awscurl-make-auth-header (awscurl-sort-headers "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6") Signature) )
    (assert-equal '(curl "--silent" "--request" "GET" "https://ec2.amazonaws.com/?Action=ImportKeyPair&KeyName=my-key" "--header" "Authorization: AWS4-HMAC-SHA256 Credential=test-access-key/20180713/us-east-1/ec2/aws4_request, SignedHeaders=content-length;host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=d7de4d3e15b72cf067af59ae00584945076967127fa42c18f470432607ff0eb8" "--header" "content-length: 15" "--header" "host: ec2.amazonaws.com" "--header" "x-amz-content-sha256: 9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6" "--header" "x-amz-date: 20180713T052018Z" "--header" "x-amz-security-token: test-session-token" "--data" "{\"json\":\"data\"}" "--verbose") (awscurl-make-request Auth (awscurl-sort-headers "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6")) "Ensure canonical (data) request is created") ]

[execute
  '(test-headers-normalized)
  '(test-data-read)
  '(test-get-credentials)
  (when *Aws_native
    '(assert-equal "cf80cd8aed482d5d1527d7dc72fceff84e6326592848447d2dc0b0e87dfc9a90" (awscurl-parse-native "testing") "Ensure OpenSSL hashes a string (native)")
    '(assert-equal "8f19bc12c7f2f3f31c2435645ff0e457d4e87f676b08d9db4ba3271bb2c3e87a" (awscurl-parse-native "testing" "cf80cd8aed482d5d1527d7dc72fceff84e6326592848447d2dc0b0e87dfc9a90") "Ensure OpenSSL hashes a string with HMAC (native)")
  )
  '(assert-equal "cf80cd8aed482d5d1527d7dc72fceff84e6326592848447d2dc0b0e87dfc9a90" (awscurl-parse-openssl "testing") "Ensure OpenSSL hashes a string")
  '(assert-equal "8f19bc12c7f2f3f31c2435645ff0e457d4e87f676b08d9db4ba3271bb2c3e87a" (awscurl-parse-openssl "testing" "-mac" "HMAC" "-macopt" "hexkey:cf80cd8aed482d5d1527d7dc72fceff84e6326592848447d2dc0b0e87dfc9a90") "Ensure OpenSSL hashes a string with HMAC")
  '(assert-equal "9a78a98c394ec90a0bc17d994c257bfbe9aa6f30f6837efb37c1f46ad86f75c6" (awscurl-file-openssl "test/data.json") "Ensure OpenSSL hashes a file")
  '(test-sort-headers)
  '(test-make-canonical)
  '(test-make-canonical-data)
  '(assert-equal "https" *Aws_protocol "Ensure default protocol is HTTPS")
  ]

(report)
