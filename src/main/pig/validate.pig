/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* pig script for validating output of Hammer. Run as a map-only job. */
REGISTER avro-tools.jar
REGISTER piggybank.jar
REGISTER json-simple.jar

DEFINE validate_script `validate.pl` SHIP('$SCRIPT');

records = LOAD '$INPUT' USING org.apache.pig.piggybank.storage.avro.AvroStorage ();
/* DUMP records; */
fields = FOREACH records GENERATE headers#'timestamp' as timestamp:bytearray, headers#'host' as host:bytearray, body as body:bytearray;
/* can't concat byte arrays in pig - need a UDF to do this "properly" */
/* content = FOREACH fields GENERATE CONCAT(timestamp, ' ', host, ' ',  body) as body:bytearray; */
reports = STREAM fields THROUGH validate_script;
STORE reports INTO '$OUTPUT';
