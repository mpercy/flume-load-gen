/**
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
package org.apache.flume.tcphammer;

import com.google.common.base.Charsets;
import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.Socket;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.util.concurrent.TimeUnit;
import org.joda.time.DateTime;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Hammer {

  private static final Logger logger = LoggerFactory.getLogger(Hammer.class);

  private static final long SECOND_IN_NANOS = 1000L * 1000L * 1000L;
  private static final long MINUTE_IN_NANOS = 60L * SECOND_IN_NANOS;

  public static void main(String[] args) {

    // usage
    if (args.length != 6) {
      System.out.println("Usage: Hammer hostname port tag event_size events_per_sec log_interval_secs");
      System.exit(1);
    }

    String host = args[0];
    InetAddress addr;
    String localhost;
    try {
      addr = InetAddress.getByName(host);
      localhost = InetAddress.getLocalHost().getCanonicalHostName();
    } catch (UnknownHostException e) {
      throw new RuntimeException("Cannot resolve host", e);
    }
    int port = Integer.parseInt(args[1]);
    String tag = args[2];
    int eventSize = Integer.parseInt(args[3]);
    int eventsPerSec = Integer.parseInt(args[4]);
    int logIntervalSecs = Integer.parseInt(args[5]);

    Socket sock;
    OutputStream out;

    try {
      logger.info("Connecting to {}:{}...", host, port);
      sock = new Socket(addr, port);
      out = new BufferedOutputStream(sock.getOutputStream());
    } catch (IOException e) {
      throw new RuntimeException("Socket problem", e);
    }

    ByteBuffer bbEnd = ByteBuffer.wrap(" ".getBytes(Charsets.US_ASCII));
    ByteBuffer bbMsg = ByteBuffer.allocate(eventSize);
    byte[] backingArray = bbMsg.array();

    // fill the backing array with X's
    for (int i = 0; i < eventSize; i++) {
      backingArray[i] = 'X';
    }
    backingArray[eventSize - 1] = '\n'; // plus a newline

    logger.info("Starting up {}/{}...", localhost, tag);

    long lastLogTime = System.nanoTime();
    long curLogIntervalNanosSlept = 0; // #nanos slept this log interval
    long curLogIntervalEventsSent = 0; // #events sent this log interval
    long lastSleepTime = System.nanoTime();

    // send the same date over and over; too slow to generate it
    //String base = "<13>" + DateTime.now() + " " + localhost + " " + tag + " ";
    //ByteBuffer bbStart = ByteBuffer.wrap(base.getBytes(Charsets.US_ASCII));

    long eventCount = 0;
    int eventsThisSec = 0;
    while (true) {
      String base = "<13>" + DateTime.now() + " " + localhost + " " + tag + " ";
      ByteBuffer bbStart = ByteBuffer.wrap(base.getBytes(Charsets.US_ASCII));
      bbMsg.put(bbStart);
      bbMsg.put(Long.toString(eventCount).getBytes(Charsets.US_ASCII));
      bbMsg.put(bbEnd);
      try {
        out.write(backingArray, 0, eventSize);
      } catch (IOException e) {
        // failed; try to reconnect
        try {
          logger.info("Caught IOException, trying to reconnect...", e);
          out.close();
          sock.close();
          sock = new Socket(addr, port);
          out = new BufferedOutputStream(sock.getOutputStream());
        } catch (IOException e2) {
          logger.error("Socket reconnect problem. Events: " + eventCount, e2);
          System.exit(1);
        }
      }

      //bbStart.flip();
      bbEnd.flip();
      bbMsg.clear();

      eventCount++;
      eventsThisSec++;
      curLogIntervalEventsSent++;

      // only check every N# events
      if (eventCount % 200L == 0) {
        long curLogTime = System.nanoTime();

        // log on 1-minute intervals
        long logDelta = curLogTime - lastLogTime;
        if (logDelta >= logIntervalSecs * SECOND_IN_NANOS) {
          logger.info("Alive. Interval: {} ms; Throttled: {} ms = {}%; " +
              "Events: {}; Rate: {} evt/sec; Total events: {}",
              new Object[] {
                logDelta / 1000000,
                curLogIntervalNanosSlept / 1000000,
                String.format("%.2f", (100 * (double) curLogIntervalNanosSlept / (double) logDelta)),
                curLogIntervalEventsSent,
                String.format("%.2f", (double) curLogIntervalEventsSent / ((double) logDelta / 1000000000D)),
                eventCount,
              });
          lastLogTime = curLogTime;
          curLogIntervalNanosSlept = 0;
          curLogIntervalEventsSent = 0;
        }
      }

      // allow for burst, then sleep
      if (eventsThisSec >= eventsPerSec) {
        // sleep for the rest of the second
        long curTime = System.nanoTime();
        long delta = curTime - lastSleepTime;
        if (delta <= SECOND_IN_NANOS) {
          long nanosToSleep = SECOND_IN_NANOS - delta;
          curLogIntervalNanosSlept += nanosToSleep;
          try {
            Thread.sleep(TimeUnit.MILLISECONDS.convert(nanosToSleep, TimeUnit.NANOSECONDS));
          } catch (InterruptedException e) {
            logger.error("Interrupted. Exiting.", e);
            return;
          }
        }
        lastSleepTime = System.nanoTime();
        eventsThisSec = 0;
      }

    }
  }

}
