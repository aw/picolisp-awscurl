# Changelog

## 1.0.0 (2020-11-16)

  * Declare library as **STABLE**: `v1.0`
  * Test with pil21
  * Update `picolisp-unit` dependency to `v3.1.0`

## 0.11.0 (2020-06-05)

  * Fix regression in 'curl' uploads, where binary data wasn't uploaded correctly.

## 0.10.0 (2020-06-05)

  * Optionally generate SHA256/HMAC hashes using 'libcrypto.so' with '--native' parameter
  * Request creation is much faster with native hashing

## 0.8.0 (2020-06-03)

  * Optionally configure the protocol (http/https) with '--protocol' parameter
  * Fix typo in README.md
  * Test with PicoLisp v20.x

## 0.7.0 (2018-07-13)

  * Replace (++ L) with (pop 'L) for backward compat with older PicoLisp
  * Add unit tests for awscurl library. #2
  * Add Travis-CI automated testing

## 0.6.0 (2018-06-19)

  * Handle file uploads by accepting '--data @filename' parameter. #4

## 0.5.0 (2018-06-18)

  * Trim leading/trailing spaces from settings in credentials file. #5 (credit: @bl8dd3r)

## 0.4.0 (2018-06-18)

  * Ensure the timezone specified is UTC. #3 (credit: @bl8dd3r)

## 0.3.0 (2018-06-18)

  * Don't ignore the temporary credentials in session token (credit: @patrixl)
  * Allow `AWS_SESSION_TOKEN` environment variable

## 0.2.0 (2018-06-18)

  * First release
