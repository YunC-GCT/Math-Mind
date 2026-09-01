# HarmonyOS `@kit.NetworkKit` HTTP Streaming API Research for SSE

**Date:** 2026-07-24
**Scope:** Research how `http` module supports progressive/streaming HTTP response body consumption for SSE (Server-Sent Events) in HarmonyOS / ArkTS.
**Project:** MindTrace (`D:\HMgent\MathMind`)
**Sources:**
- OpenHarmony 4.0 Release docs: `js-apis-http.md` (fetched from Gitee raw)
- Huawei Developer docs: `js-apis-http`, `http-request` (SPA — confirmed via OpenHarmony mirror)
- Project build configuration files

---

## 1. Project API Level Assessment

### 1.1 Top-level `build-profile.json5`

```json5
{
  "app": {
    "products": [{
      "targetSdkVersion": "6.1.1(24)",
      "compatibleSdkVersion": "6.1.1(24)",
      "runtimeOS": "HarmonyOS"
    }]
  }
}
```

**Interpretation:** `targetSdkVersion: "6.1.1(24)"` corresponds to **HarmonyOS NEXT (API 12)**. SDK version `6.x` maps to API 12+ (HarmonyOS 5.0 / NEXT).

### 1.2 Module structure

| Module | Path | Dependencies |
|--------|------|-------------|
| `entry` | `./entry` | `common`, `agents` |
| `common` | `./common` | *(none — shared HAR)* |
| `agents` | `./agents` | `common` |
| `skill` | `./skill` | — |
| `cardservice` | `./cardservice` | — |

### 1.3 Existing LLM client location

- **Source:** `common/src/main/ets/llm/LlmClient.ets`
- **Types:** `common/src/main/ets/llm/LlmTypes.ets`
- **Config:** `common/src/main/ets/llm/LlmConfig.ets`
- **Import style:** `import { http } from '@kit.NetworkKit';`

### 1.4 Compatibility verdict

| API | Min API Level | Available at API 12? |
|-----|--------------|---------------------|
| `http.createHttp()` | API 6 | ✅ Yes |
| `httpRequest.request()` | API 6 | ✅ Yes |
| `httpRequest.requestInStream()` | API 8 | ✅ Yes |
| `httpRequest.on('dataReceive')` | API 8 | ✅ Yes |
| `httpRequest.on('dataReceiveProgress')` | API 8 | ✅ Yes |
| `httpRequest.on('dataEnd')` | API 8 | ✅ Yes |
| `httpRequest.request2()` | API 10 | ✅ Yes |
| `expectDataType` | API 9 | ✅ Yes |
| `usingProtocol` | API 9 | ✅ Yes |
| `usingProxy` | API 10 | ✅ Yes |
| `caPath` | API 10 | ✅ Yes |

**All streaming APIs are fully available.** The project's API 12 target is well above the minimum API 8 requirement for `requestInStream()`.

---

## 2. Available Streaming APIs

### 2.1 `requestInStream()` — Primary streaming API (API 8+)

This is the **recommended API** for SSE consumption. It initiates an HTTP request and delivers the response body incrementally through event listeners.

```typescript
// Signature (from OpenHarmony docs)
requestInStream(url: string, callback: AsyncCallback<number>): void;
requestInStream(url: string, options: HttpRequestOptions, callback: AsyncCallback<number>): void;
```

**Key characteristics:**
- The callback receives a `number` (responseCode) on successful connection
- Response body is delivered via **event listeners** registered on the `HttpRequest` object
- Supports both GET and POST methods
- `readTimeout` controls how long the stream can stay open (set to `0` for infinite)

### 2.2 Event Listeners (API 8+)

Registered on the `HttpRequest` object returned by `createHttp()`:

| Event | Callback Signature | Description |
|-------|-------------------|-------------|
| `headersReceive` | `(header: Object) => void` | Fires when HTTP response headers are received, **before** body data |
| `dataReceive` | `(data: ArrayBuffer) => void` | Fires for each chunk of response body data received |
| `dataReceiveProgress` | `(data: { receiveSize: number, totalSize: number }) => void` | Fires with download progress stats |
| `dataEnd` | `() => void` | Fires when the response stream is complete |
| `dataError` | `(err: Error) => void` | Fires on stream/network error |

### 2.3 `request2()` — Alternative (API 10+)

A newer API that returns a `Promise<HttpResponse>` but does **not** support streaming natively — it buffers the entire response. Not suitable for SSE.

### 2.4 `request()` — Non-streaming (API 6+)

The current `LlmClient.call()` uses this. It buffers the entire response (max 5 MB). Not suitable for SSE.

---

## 3. SSE Consumption Pattern with `requestInStream()`

### 3.1 SSE Protocol Recap

SSE streams are `text/event-stream` with lines:
```
data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk",...}

data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk",...}

data: [DONE]

```

Each chunk is one or more `data:` lines terminated by a blank line (double `\n`).

### 3.2 Complete Code Example for SSE Consumption in ArkTS

```typescript
import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';

// TextDecoder for converting ArrayBuffer chunks to string
let textDecoder: util.TextDecoder = util.TextDecoder.create('utf-8');

// ---- Step 1: Create HTTP request ----
let httpRequest: http.HttpRequest = http.createHttp();

// ---- Step 2: Accumulator for partial SSE lines ----
let buffer: string = '';

// ---- Step 3: Register event listeners BEFORE calling requestInStream ----

// 3a. Headers — check content-type and status
httpRequest.on('headersReceive', (header: Object) => {
  console.info('[SSE] Headers received: ' + JSON.stringify(header));
  // Verify: header['content-type'] should include 'text/event-stream'
});

// 3b. Data chunks — parse SSE
httpRequest.on('dataReceive', (data: ArrayBuffer) => {
  // Convert ArrayBuffer to string
  let chunk: string = textDecoder.decodeToString(new Uint8Array(data));
  buffer += chunk;

  // Split on double-newline to extract complete SSE events
  while (true) {
    let idx: number = buffer.indexOf('\n\n');
    if (idx === -1) {
      break; // No complete event yet
    }
    let event: string = buffer.substring(0, idx);
    buffer = buffer.substring(idx + 2); // Remove processed event + separator

    // Parse the SSE event lines
    let lines: string[] = event.split('\n');
    for (let i = 0; i < lines.length; i++) {
      let line: string = lines[i];
      if (line.startsWith('data: ')) {
        let json: string = line.substring(6); // Strip "data: " prefix
        if (json === '[DONE]') {
          console.info('[SSE] Stream complete (received [DONE])');
          continue;
        }
        try {
          let chunk: LlmStreamChunk = JSON.parse(json) as LlmStreamChunk;
          // Process the chunk — extract delta content
          if (chunk.choices.length > 0) {
            let delta = chunk.choices[0].delta;
            if (delta.content) {
              onDelta(delta.content, 'content');
            }
            if (delta.reasoning_content) {
              onDelta(delta.reasoning_content, 'reasoning');
            }
          }
        } catch (e) {
          console.warn('[SSE] Failed to parse chunk JSON: ' + (e as Error).message);
        }
      }
    }
  }
});

// 3c. Stream complete
httpRequest.on('dataEnd', () => {
  console.info('[SSE] Stream ended');
  // Process any remaining data in buffer
  if (buffer.length > 0) {
    console.warn('[SSE] Remaining unprocessed data: ' + buffer);
  }
  httpRequest.off('dataReceive');
  httpRequest.off('dataEnd');
  httpRequest.destroy();
  onComplete();
});

// 3d. Error handling
httpRequest.on('dataError', (err: Error) => {
  console.error('[SSE] Stream error: ' + err.message);
  httpRequest.off('dataReceive');
  httpRequest.off('dataEnd');
  httpRequest.destroy();
  onError(new LlmError('SSE stream error: ' + err.message, 'NETWORK_ERROR'));
});

// ---- Step 4: Initiate the streaming request ----
let requestBody: LlmRequestBody = {
  model: 'deepseek-v4-pro',
  messages: messages,
  temperature: 0.1,
  max_tokens: 4096,
  stream: true,  // <-- KEY: enable streaming
};

httpRequest.requestInStream(
  endpointUrl,
  {
    method: http.RequestMethod.POST,
    header: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + apiKey,
      'Accept': 'text/event-stream',
    },
    extraData: JSON.stringify(requestBody),
    connectTimeout: timeoutMs,
    readTimeout: timeoutMs, // Set to 0 for infinite read timeout on long streams
  },
  (err: Error, responseCode: number) => {
    if (err) {
      console.error('[SSE] requestInStream failed: ' + err.message);
      httpRequest.destroy();
      onError(new LlmError('SSE stream connection failed: ' + err.message, 'NETWORK_ERROR'));
      return;
    }
    console.info('[SSE] Connected, response code: ' + responseCode);
    // Response body will now flow through 'dataReceive' events
  }
);
```

### 3.3 Simplified SSE Parser (without TextDecoder, for minimal imports)

If `@kit.ArkTS` `util.TextDecoder` is not available or you prefer a simpler approach, you can use the `expectDataType` option:

```typescript
// Alternative: use expectDataType to get string chunks directly
// NOTE: This is less common; the primary API returns ArrayBuffer
httpRequest.requestInStream(
  endpointUrl,
  {
    method: http.RequestMethod.POST,
    header: { /* ... */ },
    extraData: JSON.stringify(requestBody),
    expectDataType: http.HttpDataType.STRING, // Request string chunks
    readTimeout: 0, // Infinite read timeout for streaming
  },
  callback
);
```

However, according to the docs, `requestInStream` always delivers `ArrayBuffer` in `dataReceive` regardless of `expectDataType`. The `expectDataType` option primarily affects `request()`. **The safest approach is to always handle ArrayBuffer and decode to string.**

---

## 4. Recommended Implementation for `LlmClient.callStream()`

### 4.1 Design Decisions

| Decision | Rationale |
|----------|-----------|
| Use `requestInStream()` | The only streaming-capable API in HarmonyOS http module |
| Decode `ArrayBuffer` → `string` in `dataReceive` | Standard HarmonyOS pattern; `TextDecoder` from `@kit.ArkTS` |
| SSE parsing in `dataReceive` callback | Accumulate partial chunks; split on `\n\n` |
| `readTimeout: 0` | SSE streams can be long-lived; don't prematurely timeout |
| Single `HttpRequest` per `callStream()` | `HttpRequest` objects are not reusable — create/destroy per call |
| `LlmStreamCallback` already defined | `(delta: string, kind: 'reasoning' | 'content') => void` in `LlmTypes.ets` |

### 4.2 Proposed Method Signature

```typescript
// In LlmClient.ets
public async callStream(
  messages: ChatMessage[],
  onChunk: LlmStreamCallback,
  opts?: LlmCallOptions
): Promise<void>
```

### 4.3 Key Implementation Details

1. **No `async/await` on the outer method** — `callStream()` returns `Promise<void>` but resolves when the stream ends (via `dataEnd` callback). Internally, wrap the stream lifecycle in a `Promise` constructor.

2. **Error propagation** — `dataError` handler rejects the promise with `LlmError`; `dataEnd` resolves it.

3. **SSE parsing** — Must handle:
   - Chunks that split a line mid-way (buffer accumulation)
   - `data: [DONE]` sentinel
   - Multiple `data:` lines in one event (rare but valid SSE)
   - Empty chunks / keepalive comments (`: heartbeat`)

4. **Cleanup** — Always call `httpRequest.off()` for all events + `httpRequest.destroy()` in both success and error paths.

### 4.4 Pseudo-code for `callStream()`

```
callStream(messages, onChunk, opts?):
  1. Validate API key
  2. Build request body with stream: true
  3. Create httpRequest = http.createHttp()
  4. Return new Promise((resolve, reject):
     a. buffer = ''
     b. Register on('headersReceive') → validate status 200
     c. Register on('dataReceive') → decode ArrayBuffer → accumulate → parse SSE → onChunk()
     d. Register on('dataEnd') → cleanup → resolve()
     e. Register on('dataError') → cleanup → reject(LlmError)
     f. Call requestInStream(url, options, callback)
        → if callback err: cleanup → reject
  )
```

### 4.5 Caveats & Edge Cases

1. **`readTimeout: 0`** — The default `readTimeout` is 60,000ms. For SSE streams that may be silent for periods (e.g., thinking models), this needs to be set to `0` (infinite) or a very high value. The project's `DEFAULT_TIMEOUT_MS` is 120,000ms (2 min), which may be too short for long reasoning streams.

2. **Non-200 responses** — The `requestInStream` callback receives `responseCode`. If the server returns 4xx/5xx, the error body still arrives via `dataReceive`. Must check `responseCode` in the callback and reject appropriately.

3. **HTTPS only in production** — HarmonyOS restricts cleartext HTTP in production builds. Ensure the endpoint uses `https://`.

4. **No built-in SSE parser** — Unlike `EventSource` in browsers, HarmonyOS has no native SSE client. All SSE parsing must be done manually.

5. **ArkTS 1.1 strict mode** — The project uses strict ArkTS syntax (no `any`/`unknown`, explicit types, no C-style `for` loops). The SSE parser must use `while`/`for-of` loops and explicit type annotations.

---

## 5. References

- OpenHarmony `@ohos.net.http` API reference (API 4.0 Release): `js-apis-http.md`
- Huawei HarmonyOS HTTP request guide: `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/http-request`
- Project source: `common/src/main/ets/llm/LlmClient.ets` (existing `call()` using `request()`)
- Project types: `common/src/main/ets/llm/LlmTypes.ets` (existing `LlmStreamChunk`, `LlmStreamCallback`)
