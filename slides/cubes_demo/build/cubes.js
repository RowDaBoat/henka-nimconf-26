// include: shell.js
// include: minimum_runtime_check.js
(function() {
  // "30.0.0" -> 300000
  function humanReadableVersionToPacked(str) {
    str = str.split("-")[0];
    // Remove any trailing part from e.g. "12.53.3-alpha"
    var vers = str.split(".").slice(0, 3);
    while (vers.length < 3) vers.push("00");
    vers = vers.map((n, i, arr) => n.padStart(2, "0"));
    return vers.join("");
  }
  // 300000 -> "30.0.0"
  var packedVersionToHumanReadable = n => [ n / 1e4 | 0, (n / 100 | 0) % 100, n % 100 ].join(".");
  var TARGET_NOT_SUPPORTED = 2147483647;
  // Note: We use a typeof check here instead of optional chaining using
  // globalThis because older browsers might not have globalThis defined.
  var currentNodeVersion = typeof process !== "undefined" && process.versions?.node ? humanReadableVersionToPacked(process.versions.node) : TARGET_NOT_SUPPORTED;
  if (currentNodeVersion < 180300) {
    throw new Error(`This emscripten-generated code requires node v${packedVersionToHumanReadable(180300)} (detected v${packedVersionToHumanReadable(currentNodeVersion)})`);
  }
  var userAgent = typeof navigator !== "undefined" && navigator.userAgent;
  if (!userAgent) {
    return;
  }
  var currentSafariVersion = userAgent.includes("Safari/") && !userAgent.includes("Chrome/") && userAgent.match(/Version\/(\d+\.?\d*\.?\d*)/) ? humanReadableVersionToPacked(userAgent.match(/Version\/(\d+\.?\d*\.?\d*)/)[1]) : TARGET_NOT_SUPPORTED;
  if (currentSafariVersion < 15e4) {
    throw new Error(`This emscripten-generated code requires Safari v${packedVersionToHumanReadable(15e4)} (detected v${currentSafariVersion})`);
  }
  var currentFirefoxVersion = userAgent.match(/Firefox\/(\d+(?:\.\d+)?)/) ? parseFloat(userAgent.match(/Firefox\/(\d+(?:\.\d+)?)/)[1]) : TARGET_NOT_SUPPORTED;
  if (currentFirefoxVersion < 79) {
    throw new Error(`This emscripten-generated code requires Firefox v79 (detected v${currentFirefoxVersion})`);
  }
  var currentChromeVersion = userAgent.match(/Chrome\/(\d+(?:\.\d+)?)/) ? parseFloat(userAgent.match(/Chrome\/(\d+(?:\.\d+)?)/)[1]) : TARGET_NOT_SUPPORTED;
  if (currentChromeVersion < 85) {
    throw new Error(`This emscripten-generated code requires Chrome v85 (detected v${currentChromeVersion})`);
  }
})();

// end include: minimum_runtime_check.js
// The Module object: Our interface to the outside world. We import
// and export values on it. There are various ways Module can be used:
// 1. Not defined. We create it here
// 2. A function parameter, function(moduleArg) => Promise<Module>
// 3. pre-run appended it, var Module = {}; ..generated code..
// 4. External script tag defines var Module.
// We need to check if Module already exists (e.g. case 3 above).
// Substitution will be replaced with actual code on later stage of the build,
// this way Closure Compiler will not mangle it (e.g. case 4. above).
// Note that if you want to run closure, and also to use Module
// after the generated code, you will need to define   var Module = {};
// before the code. Then that object will be used in the code, and you
// can continue to use Module afterwards as well.
var Module = typeof Module != "undefined" ? Module : {};

// Determine the runtime environment we are in. You can customize this by
// setting the ENVIRONMENT setting at compile time (see settings.js).
// Attempt to auto-detect the environment
var ENVIRONMENT_IS_WEB = !!globalThis.window;

var ENVIRONMENT_IS_WORKER = !!globalThis.WorkerGlobalScope;

// N.b. Electron.js environment is simultaneously a NODE-environment, but
// also a web environment.
var ENVIRONMENT_IS_NODE = globalThis.process?.versions?.node && globalThis.process?.type != "renderer";

var ENVIRONMENT_IS_SHELL = !ENVIRONMENT_IS_WEB && !ENVIRONMENT_IS_NODE && !ENVIRONMENT_IS_WORKER;

// --pre-jses are emitted after the Module integration code, so that they can
// refer to Module (if they choose; they can also define Module)
var arguments_ = [];

var thisProgram = "./this.program";

var quit_ = (status, toThrow) => {
  throw toThrow;
};

// In MODULARIZE mode _scriptName needs to be captured already at the very top of the page immediately when the page is parsed, so it is generated there
// before the page load. In non-MODULARIZE modes generate it here.
var _scriptName = globalThis.document?.currentScript?.src;

if (typeof __filename != "undefined") {
  // Node
  _scriptName = __filename;
} else if (ENVIRONMENT_IS_WORKER) {
  _scriptName = self.location.href;
}

// `/` should be present at the end if `scriptDirectory` is not empty
var scriptDirectory = "";

function locateFile(path) {
  if (Module["locateFile"]) {
    return Module["locateFile"](path, scriptDirectory);
  }
  return scriptDirectory + path;
}

// Hooks that are implemented differently in different runtime environments.
var readAsync, readBinary;

if (ENVIRONMENT_IS_NODE) {
  const isNode = globalThis.process?.versions?.node && globalThis.process?.type != "renderer";
  if (!isNode) throw new Error("not compiled for this environment (did you build to HTML and try to run it not on the web, or set ENVIRONMENT to something - like node - and run it someplace else - like on the web?)");
  // These modules will usually be used on Node.js. Load them eagerly to avoid
  // the complexity of lazy-loading.
  var fs = require("node:fs");
  scriptDirectory = __dirname + "/";
  // include: node_shell_read.js
  readBinary = filename => {
    // We need to re-wrap `file://` strings to URLs.
    filename = isFileURI(filename) ? new URL(filename) : filename;
    var ret = fs.readFileSync(filename);
    assert(Buffer.isBuffer(ret));
    return ret;
  };
  readAsync = async (filename, binary = true) => {
    // See the comment in the `readBinary` function.
    filename = isFileURI(filename) ? new URL(filename) : filename;
    var ret = fs.readFileSync(filename, binary ? undefined : "utf8");
    assert(binary ? Buffer.isBuffer(ret) : typeof ret == "string");
    return ret;
  };
  // end include: node_shell_read.js
  if (process.argv.length > 1) {
    thisProgram = process.argv[1].replace(/\\/g, "/");
  }
  arguments_ = process.argv.slice(2);
  // MODULARIZE will export the module in the proper place outside, we don't need to export here
  if (typeof module != "undefined") {
    module["exports"] = Module;
  }
  quit_ = (status, toThrow) => {
    process.exitCode = status;
    throw toThrow;
  };
} else if (ENVIRONMENT_IS_SHELL) {} else // Note that this includes Node.js workers when relevant (pthreads is enabled).
// Node.js workers are detected as a combination of ENVIRONMENT_IS_WORKER and
// ENVIRONMENT_IS_NODE.
if (ENVIRONMENT_IS_WEB || ENVIRONMENT_IS_WORKER) {
  try {
    scriptDirectory = new URL(".", _scriptName).href;
  } catch {}
  if (!(globalThis.window || globalThis.WorkerGlobalScope)) throw new Error("not compiled for this environment (did you build to HTML and try to run it not on the web, or set ENVIRONMENT to something - like node - and run it someplace else - like on the web?)");
  {
    // include: web_or_worker_shell_read.js
    if (ENVIRONMENT_IS_WORKER) {
      readBinary = url => {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", url, false);
        xhr.responseType = "arraybuffer";
        xhr.send(null);
        return new Uint8Array(/** @type{!ArrayBuffer} */ (xhr.response));
      };
    }
    readAsync = async url => {
      // Fetch has some additional restrictions over XHR, like it can't be used on a file:// url.
      // See https://github.com/github/fetch/pull/92#issuecomment-140665932
      // Cordova or Electron apps are typically loaded from a file:// url.
      // So use XHR on webview if URL is a file URL.
      if (isFileURI(url)) {
        return new Promise((resolve, reject) => {
          var xhr = new XMLHttpRequest;
          xhr.open("GET", url, true);
          xhr.responseType = "arraybuffer";
          xhr.onload = () => {
            if (xhr.status == 200 || (xhr.status == 0 && xhr.response)) {
              // file URLs can return 0
              resolve(xhr.response);
              return;
            }
            reject(xhr.status);
          };
          xhr.onerror = reject;
          xhr.send(null);
        });
      }
      var response = await fetch(url, {
        credentials: "same-origin"
      });
      if (response.ok) {
        return response.arrayBuffer();
      }
      throw new Error(response.status + " : " + response.url);
    };
  }
} else {
  throw new Error("environment detection error");
}

var out = console.log.bind(console);

var err = console.error.bind(console);

var IDBFS = "IDBFS is no longer included by default; build with -lidbfs.js";

var PROXYFS = "PROXYFS is no longer included by default; build with -lproxyfs.js";

var WORKERFS = "WORKERFS is no longer included by default; build with -lworkerfs.js";

var FETCHFS = "FETCHFS is no longer included by default; build with -lfetchfs.js";

var ICASEFS = "ICASEFS is no longer included by default; build with -licasefs.js";

var JSFILEFS = "JSFILEFS is no longer included by default; build with -ljsfilefs.js";

var OPFS = "OPFS is no longer included by default; build with -lopfs.js";

var NODEFS = "NODEFS is no longer included by default; build with -lnodefs.js";

// perform assertions in shell.js after we set up out() and err(), as otherwise
// if an assertion fails it cannot print the message
assert(!ENVIRONMENT_IS_SHELL, "shell environment detected but not enabled at build time.  Add `shell` to `-sENVIRONMENT` to enable.");

// end include: shell.js
// include: preamble.js
// === Preamble library stuff ===
// Documentation for the public APIs defined in this file must be updated in:
//    site/source/docs/api_reference/preamble.js.rst
// A prebuilt local version of the documentation is available at:
//    site/build/text/docs/api_reference/preamble.js.txt
// You can also build docs locally as HTML or other formats in site/
// An online HTML version (which may be of a different version of Emscripten)
//    is up at http://kripken.github.io/emscripten-site/docs/api_reference/preamble.js.html
var wasmBinary;

if (!globalThis.WebAssembly) {
  err("no native wasm support detected");
}

// Wasm globals
//========================================
// Runtime essentials
//========================================
// whether we are quitting the application. no code should run after this.
// set in exit() and abort()
var ABORT = false;

// set by exit() and abort().  Passed to 'onExit' handler.
// NOTE: This is also used as the process return code in shell environments
// but only when noExitRuntime is false.
var EXITSTATUS;

// In STRICT mode, we only define assert() when ASSERTIONS is set.  i.e. we
// don't define it at all in release modes.  This matches the behaviour of
// MINIMAL_RUNTIME.
// TODO(sbc): Make this the default even without STRICT enabled.
/** @type {function(*, string=)} */ function assert(condition, text) {
  if (!condition) {
    abort("Assertion failed" + (text ? ": " + text : ""));
  }
}

// We used to include malloc/free by default in the past. Show a helpful error in
// builds with assertions.
/**
 * Indicates whether filename is delivered via file protocol (as opposed to http/https)
 * @noinline
 */ var isFileURI = filename => filename.startsWith("file://");

// include: runtime_common.js
// include: runtime_stack_check.js
// Initializes the stack cookie. Called at the startup of main and at the startup of each thread in pthreads mode.
function writeStackCookie() {
  var max = _emscripten_stack_get_end();
  assert((max & 3) == 0);
  // If the stack ends at address zero we write our cookies 4 bytes into the
  // stack.  This prevents interference with SAFE_HEAP and ASAN which also
  // monitor writes to address zero.
  if (max == 0) {
    max += 4;
  }
  // The stack grow downwards towards _emscripten_stack_get_end.
  // We write cookies to the final two words in the stack and detect if they are
  // ever overwritten.
  HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((max) >> 2), "storing")] = 34821223;
  checkInt32(34821223);
  HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((max) + (4)) >> 2), "storing")] = 2310721022;
  checkInt32(2310721022);
}

function checkStackCookie() {
  if (ABORT) return;
  var max = _emscripten_stack_get_end();
  // See writeStackCookie().
  if (max == 0) {
    max += 4;
  }
  var cookie1 = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((max) >> 2), "loading")];
  var cookie2 = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((max) + (4)) >> 2), "loading")];
  if (cookie1 != 34821223 || cookie2 != 2310721022) {
    abort(`Stack overflow! Stack cookie has been overwritten at ${ptrToString(max)}, expected hex dwords 0x89BACDFE and 0x2135467, but received ${ptrToString(cookie2)} ${ptrToString(cookie1)}`);
  }
}

// end include: runtime_stack_check.js
// include: runtime_exceptions.js
// Base Emscripten EH error class
class EmscriptenEH {}

class EmscriptenSjLj extends EmscriptenEH {}

// end include: runtime_exceptions.js
// include: runtime_debug.js
var runtimeDebug = true;

// Switch to false at runtime to disable logging at the right times
// Used by XXXXX_DEBUG settings to output debug messages.
function dbg(...args) {
  if (!runtimeDebug && typeof runtimeDebug != "undefined") return;
  // TODO(sbc): Make this configurable somehow.  Its not always convenient for
  // logging to show up as warnings.
  console.warn(...args);
}

// Endianness check
(() => {
  var h16 = new Int16Array(1);
  var h8 = new Int8Array(h16.buffer);
  h16[0] = 25459;
  if (h8[0] !== 115 || h8[1] !== 99) abort("Runtime error: expected the system to be little-endian! (Run with -sSUPPORT_BIG_ENDIAN to bypass)");
})();

function consumedModuleProp(prop) {
  if (!Object.getOwnPropertyDescriptor(Module, prop)) {
    Object.defineProperty(Module, prop, {
      configurable: true,
      set() {
        abort(`Attempt to set \`Module.${prop}\` after it has already been processed.  This can happen, for example, when code is injected via '--post-js' rather than '--pre-js'`);
      }
    });
  }
}

function makeInvalidEarlyAccess(name) {
  return () => assert(false, `call to '${name}' via reference taken before Wasm module initialization`);
}

function ignoredModuleProp(prop) {
  if (Object.getOwnPropertyDescriptor(Module, prop)) {
    abort(`\`Module.${prop}\` was supplied but \`${prop}\` not included in INCOMING_MODULE_JS_API`);
  }
}

// forcing the filesystem exports a few things by default
function isExportedByForceFilesystem(name) {
  return name === "FS_createPath" || name === "FS_createDataFile" || name === "FS_createPreloadedFile" || name === "FS_preloadFile" || name === "FS_unlink" || name === "addRunDependency" || // The old FS has some functionality that WasmFS lacks.
  name === "FS_createLazyFile" || name === "FS_createDevice" || name === "removeRunDependency";
}

/**
 * Intercept access to a symbols in the global symbol.  This enables us to give
 * informative warnings/errors when folks attempt to use symbols they did not
 * include in their build, or no symbols that no longer exist.
 *
 * We don't define this in MODULARIZE mode since in that mode emscripten symbols
 * are never placed in the global scope.
 */ function hookGlobalSymbolAccess(sym, func) {
  if (!Object.getOwnPropertyDescriptor(globalThis, sym)) {
    Object.defineProperty(globalThis, sym, {
      configurable: true,
      get() {
        func();
        return undefined;
      }
    });
  }
}

function missingGlobal(sym, msg) {
  hookGlobalSymbolAccess(sym, () => {
    warnOnce(`\`${sym}\` is no longer defined by emscripten. ${msg}`);
  });
}

missingGlobal("buffer", "Please use HEAP8.buffer or wasmMemory.buffer");

missingGlobal("asm", "Please use wasmExports instead");

function missingLibrarySymbol(sym) {
  hookGlobalSymbolAccess(sym, () => {
    // Can't `abort()` here because it would break code that does runtime
    // checks.  e.g. `if (typeof SDL === 'undefined')`.
    var msg = `\`${sym}\` is a library symbol and not included by default; add it to your library.js __deps or to DEFAULT_LIBRARY_FUNCS_TO_INCLUDE on the command line`;
    // DEFAULT_LIBRARY_FUNCS_TO_INCLUDE requires the name as it appears in
    // library.js, which means $name for a JS name with no prefix, or name
    // for a JS name like _name.
    var librarySymbol = sym;
    if (!librarySymbol.startsWith("_")) {
      librarySymbol = "$" + sym;
    }
    msg += ` (e.g. -sDEFAULT_LIBRARY_FUNCS_TO_INCLUDE='${librarySymbol}')`;
    if (isExportedByForceFilesystem(sym)) {
      msg += ". Alternatively, forcing filesystem support (-sFORCE_FILESYSTEM) can export this for you";
    }
    warnOnce(msg);
  });
  // Any symbol that is not included from the JS library is also (by definition)
  // not exported on the Module object.
  unexportedRuntimeSymbol(sym);
}

function unexportedRuntimeSymbol(sym) {
  if (!Object.getOwnPropertyDescriptor(Module, sym)) {
    Object.defineProperty(Module, sym, {
      configurable: true,
      get() {
        var msg = `'${sym}' was not exported. add it to EXPORTED_RUNTIME_METHODS (see the Emscripten FAQ)`;
        if (isExportedByForceFilesystem(sym)) {
          msg += ". Alternatively, forcing filesystem support (-sFORCE_FILESYSTEM) can export this for you";
        }
        abort(msg);
      }
    });
  }
}

var MAX_UINT8 = (2 ** 8) - 1;

var MAX_UINT16 = (2 ** 16) - 1;

var MAX_UINT32 = (2 ** 32) - 1;

var MAX_UINT53 = (2 ** 53) - 1;

var MAX_UINT64 = (2 ** 64) - 1;

var MIN_INT8 = -(2 ** (8 - 1));

var MIN_INT16 = -(2 ** (16 - 1));

var MIN_INT32 = -(2 ** (32 - 1));

var MIN_INT53 = -(2 ** (53 - 1));

var MIN_INT64 = -(2 ** (64 - 1));

function checkInt(value, bits, min, max) {
  assert(Number.isInteger(Number(value)), `attempt to write non-integer (${value}) into integer heap`);
  assert(value <= max, `value (${value}) too large to write as ${bits}-bit value`);
  assert(value >= min, `value (${value}) too small to write as ${bits}-bit value`);
}

var checkInt1 = value => checkInt(value, 1, 1);

var checkInt8 = value => checkInt(value, 8, MIN_INT8, MAX_UINT8);

var checkInt16 = value => checkInt(value, 16, MIN_INT16, MAX_UINT16);

var checkInt32 = value => checkInt(value, 32, MIN_INT32, MAX_UINT32);

var checkInt53 = value => checkInt(value, 53, MIN_INT53, MAX_UINT53);

var checkInt64 = value => checkInt(value, 64, MIN_INT64, MAX_UINT64);

// end include: runtime_debug.js
// include: runtime_safe_heap.js
function SAFE_HEAP_INDEX(arr, idx, action) {
  const bytes = arr.BYTES_PER_ELEMENT;
  const dest = idx * bytes;
  if (idx <= 0) abort(`segmentation fault ${action} ${bytes} bytes at address ${dest}`);
  if (runtimeInitialized) {
    var brk = _sbrk(0);
    if (dest + bytes > brk) abort(`segmentation fault, exceeded the top of the available dynamic heap when ${action} ${bytes} bytes at address ${dest}. DYNAMICTOP=${brk}`);
    if (brk < _emscripten_stack_get_base()) abort(`brk >= _emscripten_stack_get_base() (brk=${brk}, _emscripten_stack_get_base()=${_emscripten_stack_get_base()})`);
    // sbrk-managed memory must be above the stack
    if (brk > wasmMemory.buffer.byteLength) abort(`brk <= wasmMemory.buffer.byteLength (brk=${brk}, wasmMemory.buffer.byteLength=${wasmMemory.buffer.byteLength})`);
  }
  return idx;
}

function segfault() {
  abort("segmentation fault");
}

function alignfault() {
  abort("alignment fault");
}

// end include: runtime_safe_heap.js
// Memory management
var runtimeInitialized = false;

function updateMemoryViews() {
  var b = wasmMemory.buffer;
  HEAP8 = new Int8Array(b);
  HEAP16 = new Int16Array(b);
  HEAPU8 = new Uint8Array(b);
  HEAPU16 = new Uint16Array(b);
  HEAP32 = new Int32Array(b);
  HEAPU32 = new Uint32Array(b);
  HEAPF32 = new Float32Array(b);
  HEAPF64 = new Float64Array(b);
  HEAP64 = new BigInt64Array(b);
  HEAPU64 = new BigUint64Array(b);
}

// include: memoryprofiler.js
// end include: memoryprofiler.js
// end include: runtime_common.js
assert(globalThis.Int32Array && globalThis.Float64Array && Int32Array.prototype.subarray && Int32Array.prototype.set, "JS engine does not provide full typed array support");

function preRun() {
  if (Module["preRun"]) {
    if (typeof Module["preRun"] == "function") Module["preRun"] = [ Module["preRun"] ];
    while (Module["preRun"].length) {
      addOnPreRun(Module["preRun"].shift());
    }
  }
  consumedModuleProp("preRun");
  // Begin ATPRERUNS hooks
  callRuntimeCallbacks(onPreRuns);
}

function initRuntime() {
  assert(!runtimeInitialized);
  runtimeInitialized = true;
  setStackLimits();
  checkStackCookie();
  // No ATINITS hooks
  wasmExports["__wasm_call_ctors"]();
}

function preMain() {
  checkStackCookie();
}

function postRun() {
  checkStackCookie();
  // PThreads reuse the runtime from the main thread.
  if (Module["postRun"]) {
    if (typeof Module["postRun"] == "function") Module["postRun"] = [ Module["postRun"] ];
    while (Module["postRun"].length) {
      addOnPostRun(Module["postRun"].shift());
    }
  }
  consumedModuleProp("postRun");
  // Begin ATPOSTRUNS hooks
  callRuntimeCallbacks(onPostRuns);
}

/**
 * @param {string|number=} what
 */ function abort(what) {
  Module["onAbort"]?.(what);
  what = `Aborted(${what})`;
  // TODO(sbc): Should we remove printing and leave it up to whoever
  // catches the exception?
  err(what);
  ABORT = true;
  // Use a wasm runtime error, because a JS error might be seen as a foreign
  // exception, which means we'd run destructors on it. We need the error to
  // simply make the program stop.
  // FIXME This approach does not work in Wasm EH because it currently does not assume
  // all RuntimeErrors are from traps; it decides whether a RuntimeError is from
  // a trap or not based on a hidden field within the object. So at the moment
  // we don't have a way of throwing a wasm trap from JS. TODO Make a JS API that
  // allows this in the wasm spec.
  // Suppress closure compiler warning here. Closure compiler's builtin extern
  // definition for WebAssembly.RuntimeError claims it takes no arguments even
  // though it can.
  // TODO(https://github.com/google/closure-compiler/pull/3913): Remove if/when upstream closure gets fixed.
  /** @suppress {checkTypes} */ var e = new WebAssembly.RuntimeError(what);
  // Throw the error whether or not MODULARIZE is set because abort is used
  // in code paths apart from instantiation where an exception is expected
  // to be thrown when abort is called.
  throw e;
}

// show errors on likely calls to FS when it was not included
function fsMissing() {
  abort("Filesystem support (FS) was not included. The problem is that you are using files from JS, but files were not used from C/C++, so filesystem support was not auto-included. You can force-include filesystem support with -sFORCE_FILESYSTEM");
}

var FS = {
  init: fsMissing,
  createDataFile: fsMissing,
  createPreloadedFile: fsMissing,
  createLazyFile: fsMissing,
  open: fsMissing,
  mkdev: fsMissing,
  registerDevice: fsMissing,
  analyzePath: fsMissing,
  ErrnoError: fsMissing
};

function createExportWrapper(name, nargs) {
  return (...args) => {
    assert(runtimeInitialized, `native function \`${name}\` called before runtime initialization`);
    var f = wasmExports[name];
    assert(f, `exported native function \`${name}\` not found`);
    // Only assert for too many arguments. Too few can be valid since the missing arguments will be zero filled.
    assert(args.length <= nargs, `native function \`${name}\` called with ${args.length} args but expects ${nargs}`);
    return f(...args);
  };
}

var wasmBinaryFile;

function findWasmBinary() {
  return locateFile("cubes.wasm");
}

function getBinarySync(file) {
  if (file == wasmBinaryFile && wasmBinary) {
    return new Uint8Array(wasmBinary);
  }
  if (readBinary) {
    return readBinary(file);
  }
  // Throwing a plain string here, even though it not normally advisable since
  // this gets turning into an `abort` in instantiateArrayBuffer.
  throw "both async and sync fetching of the wasm failed";
}

async function getWasmBinary(binaryFile) {
  // If we don't have the binary yet, load it asynchronously using readAsync.
  if (!wasmBinary) {
    // Fetch the binary using readAsync
    try {
      var response = await readAsync(binaryFile);
      return new Uint8Array(response);
    } catch {}
  }
  // Otherwise, getBinarySync should be able to get it synchronously
  return getBinarySync(binaryFile);
}

async function instantiateArrayBuffer(binaryFile, imports) {
  try {
    var binary = await getWasmBinary(binaryFile);
    var instance = await WebAssembly.instantiate(binary, imports);
    return instance;
  } catch (reason) {
    err(`failed to asynchronously prepare wasm: ${reason}`);
    // Warn on some common problems.
    if (isFileURI(binaryFile)) {
      err(`warning: Loading from a file URI (${binaryFile}) is not supported in most browsers. See https://emscripten.org/docs/getting_started/FAQ.html#how-do-i-run-a-local-webserver-for-testing-why-does-my-program-stall-in-downloading-or-preparing`);
    }
    abort(reason);
  }
}

async function instantiateAsync(binary, binaryFile, imports) {
  if (!binary && !isFileURI(binaryFile) && !ENVIRONMENT_IS_NODE) {
    try {
      var response = fetch(binaryFile, {
        credentials: "same-origin"
      });
      var instantiationResult = await WebAssembly.instantiateStreaming(response, imports);
      return instantiationResult;
    } catch (reason) {
      // We expect the most common failure cause to be a bad MIME type for the binary,
      // in which case falling back to ArrayBuffer instantiation should work.
      err(`wasm streaming compile failed: ${reason}`);
      err("falling back to ArrayBuffer instantiation");
    }
  }
  return instantiateArrayBuffer(binaryFile, imports);
}

function getWasmImports() {
  // prepare imports
  var imports = {
    "env": wasmImports,
    "wasi_snapshot_preview1": wasmImports
  };
  return imports;
}

// Create the wasm instance.
// Receives the wasm imports, returns the exports.
async function createWasm() {
  // Load the wasm module and create an instance of using native support in the JS engine.
  // handle a generated wasm instance, receiving its exports and
  // performing other necessary setup
  /** @param {WebAssembly.Module=} module*/ function receiveInstance(instance, module) {
    wasmExports = instance.exports;
    assignWasmExports(wasmExports);
    updateMemoryViews();
    removeRunDependency("wasm-instantiate");
    return wasmExports;
  }
  addRunDependency("wasm-instantiate");
  // Prefer streaming instantiation if available.
  // Async compilation can be confusing when an error on the page overwrites Module
  // (for example, if the order of elements is wrong, and the one defining Module is
  // later), so we save Module and check it later.
  var trueModule = Module;
  function receiveInstantiationResult(result) {
    // 'result' is a ResultObject object which has both the module and instance.
    // receiveInstance() will swap in the exports (to Module.asm) so they can be called
    assert(Module === trueModule, "the Module object should not be replaced during async compilation - perhaps the order of HTML elements is wrong?");
    trueModule = null;
    // TODO: Due to Closure regression https://github.com/google/closure-compiler/issues/3193, the above line no longer optimizes out down to the following line.
    // When the regression is fixed, can restore the above PTHREADS-enabled path.
    return receiveInstance(result["instance"]);
  }
  var info = getWasmImports();
  // User shell pages can write their own Module.instantiateWasm = function(imports, successCallback) callback
  // to manually instantiate the Wasm module themselves. This allows pages to
  // run the instantiation parallel to any other async startup actions they are
  // performing.
  // Also pthreads and wasm workers initialize the wasm instance through this
  // path.
  if (Module["instantiateWasm"]) {
    return new Promise((resolve, reject) => {
      try {
        Module["instantiateWasm"](info, (inst, mod) => {
          resolve(receiveInstance(inst, mod));
        });
      } catch (e) {
        err(`Module.instantiateWasm callback failed with error: ${e}`);
        reject(e);
      }
    });
  }
  wasmBinaryFile ??= findWasmBinary();
  var result = await instantiateAsync(wasmBinary, wasmBinaryFile, info);
  var exports = receiveInstantiationResult(result);
  return exports;
}

// end include: preamble.js
// Begin JS library code
class ExitStatus {
  name="ExitStatus";
  constructor(status) {
    this.message = `Program terminated with exit(${status})`;
    this.status = status;
  }
}

/** @type {!Int16Array} */ var HEAP16;

/** @type {!Int32Array} */ var HEAP32;

/** not-@type {!BigInt64Array} */ var HEAP64;

/** @type {!Int8Array} */ var HEAP8;

/** @type {!Float32Array} */ var HEAPF32;

/** @type {!Float64Array} */ var HEAPF64;

/** @type {!Uint16Array} */ var HEAPU16;

/** @type {!Uint32Array} */ var HEAPU32;

/** not-@type {!BigUint64Array} */ var HEAPU64;

/** @type {!Uint8Array} */ var HEAPU8;

var callRuntimeCallbacks = callbacks => {
  while (callbacks.length > 0) {
    // Pass the module as the first argument.
    callbacks.shift()(Module);
  }
};

var onPostRuns = [];

var addOnPostRun = cb => onPostRuns.push(cb);

var onPreRuns = [];

var addOnPreRun = cb => onPreRuns.push(cb);

var runDependencies = 0;

var dependenciesFulfilled = null;

var runDependencyTracking = {};

var runDependencyWatcher = null;

var removeRunDependency = id => {
  runDependencies--;
  Module["monitorRunDependencies"]?.(runDependencies);
  assert(id, "removeRunDependency requires an ID");
  assert(runDependencyTracking[id]);
  delete runDependencyTracking[id];
  if (runDependencies == 0) {
    if (runDependencyWatcher !== null) {
      clearInterval(runDependencyWatcher);
      runDependencyWatcher = null;
    }
    if (dependenciesFulfilled) {
      var callback = dependenciesFulfilled;
      dependenciesFulfilled = null;
      callback();
    }
  }
};

var addRunDependency = id => {
  runDependencies++;
  Module["monitorRunDependencies"]?.(runDependencies);
  assert(id, "addRunDependency requires an ID");
  assert(!runDependencyTracking[id]);
  runDependencyTracking[id] = 1;
  if (runDependencyWatcher === null && globalThis.setInterval) {
    // Check for missing dependencies every few seconds
    runDependencyWatcher = setInterval(() => {
      if (ABORT) {
        clearInterval(runDependencyWatcher);
        runDependencyWatcher = null;
        return;
      }
      var shown = false;
      for (var dep in runDependencyTracking) {
        if (!shown) {
          shown = true;
          err("still waiting on run dependencies:");
        }
        err(`dependency: ${dep}`);
      }
      if (shown) {
        err("(end of list)");
      }
    }, 1e4);
    // Prevent this timer from keeping the runtime alive if nothing
    // else is.
    runDependencyWatcher.unref?.();
  }
};

/**
   * @param {number} ptr
   * @param {string} type
   */ function getValue(ptr, type = "i8") {
  if (type.endsWith("*")) type = "*";
  switch (type) {
   case "i1":
    return HEAP8[SAFE_HEAP_INDEX(HEAP8, ptr, "loading")];

   case "i8":
    return HEAP8[SAFE_HEAP_INDEX(HEAP8, ptr, "loading")];

   case "i16":
    return HEAP16[SAFE_HEAP_INDEX(HEAP16, ((ptr) >> 1), "loading")];

   case "i32":
    return HEAP32[SAFE_HEAP_INDEX(HEAP32, ((ptr) >> 2), "loading")];

   case "i64":
    return HEAP64[SAFE_HEAP_INDEX(HEAP64, ((ptr) >> 3), "loading")];

   case "float":
    return HEAPF32[SAFE_HEAP_INDEX(HEAPF32, ((ptr) >> 2), "loading")];

   case "double":
    return HEAPF64[SAFE_HEAP_INDEX(HEAPF64, ((ptr) >> 3), "loading")];

   case "*":
    return HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")];

   default:
    abort(`invalid type for getValue: ${type}`);
  }
}

var noExitRuntime = true;

function ptrToString(ptr) {
  assert(typeof ptr === "number", `ptrToString expects a number, got ${typeof ptr}`);
  // Convert to 32-bit unsigned value
  ptr >>>= 0;
  return "0x" + ptr.toString(16).padStart(8, "0");
}

var setStackLimits = () => {
  var stackLow = _emscripten_stack_get_base();
  var stackHigh = _emscripten_stack_get_end();
  ___set_stack_limits(stackLow, stackHigh);
};

/**
   * @param {number} ptr
   * @param {number} value
   * @param {string} type
   */ function setValue(ptr, value, type = "i8") {
  if (type.endsWith("*")) type = "*";
  switch (type) {
   case "i1":
    HEAP8[SAFE_HEAP_INDEX(HEAP8, ptr, "storing")] = value;
    checkInt8(value);
    break;

   case "i8":
    HEAP8[SAFE_HEAP_INDEX(HEAP8, ptr, "storing")] = value;
    checkInt8(value);
    break;

   case "i16":
    HEAP16[SAFE_HEAP_INDEX(HEAP16, ((ptr) >> 1), "storing")] = value;
    checkInt16(value);
    break;

   case "i32":
    HEAP32[SAFE_HEAP_INDEX(HEAP32, ((ptr) >> 2), "storing")] = value;
    checkInt32(value);
    break;

   case "i64":
    HEAP64[SAFE_HEAP_INDEX(HEAP64, ((ptr) >> 3), "storing")] = BigInt(value);
    checkInt64(value);
    break;

   case "float":
    HEAPF32[SAFE_HEAP_INDEX(HEAPF32, ((ptr) >> 2), "storing")] = value;
    break;

   case "double":
    HEAPF64[SAFE_HEAP_INDEX(HEAPF64, ((ptr) >> 3), "storing")] = value;
    break;

   case "*":
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "storing")] = value;
    break;

   default:
    abort(`invalid type for setValue: ${type}`);
  }
}

var stackRestore = val => __emscripten_stack_restore(val);

var stackSave = () => _emscripten_stack_get_current();

var warnOnce = text => {
  warnOnce.shown ||= {};
  if (!warnOnce.shown[text]) {
    warnOnce.shown[text] = 1;
    if (ENVIRONMENT_IS_NODE) text = "warning: " + text;
    err(text);
  }
};

var UTF8Decoder = globalThis.TextDecoder && new TextDecoder;

var findStringEnd = (heapOrArray, idx, maxBytesToRead, ignoreNul) => {
  var maxIdx = idx + maxBytesToRead;
  if (ignoreNul) return maxIdx;
  // TextDecoder needs to know the byte length in advance, it doesn't stop on
  // null terminator by itself.
  // As a tiny code save trick, compare idx against maxIdx using a negation,
  // so that maxBytesToRead=undefined/NaN means Infinity.
  while (heapOrArray[idx] && !(idx >= maxIdx)) ++idx;
  return idx;
};

/**
   * Given a pointer 'idx' to a null-terminated UTF8-encoded string in the given
   * array that contains uint8 values, returns a copy of that string as a
   * Javascript String object.
   * heapOrArray is either a regular array, or a JavaScript typed array view.
   * @param {number=} idx
   * @param {number=} maxBytesToRead
   * @param {boolean=} ignoreNul - If true, the function will not stop on a NUL character.
   * @return {string}
   */ var UTF8ArrayToString = (heapOrArray, idx = 0, maxBytesToRead, ignoreNul) => {
  var endPtr = findStringEnd(heapOrArray, idx, maxBytesToRead, ignoreNul);
  // When using conditional TextDecoder, skip it for short strings as the overhead of the native call is not worth it.
  if (endPtr - idx > 16 && heapOrArray.buffer && UTF8Decoder) {
    return UTF8Decoder.decode(heapOrArray.subarray(idx, endPtr));
  }
  var str = "";
  while (idx < endPtr) {
    // For UTF8 byte structure, see:
    // http://en.wikipedia.org/wiki/UTF-8#Description
    // https://www.ietf.org/rfc/rfc2279.txt
    // https://tools.ietf.org/html/rfc3629
    var u0 = heapOrArray[idx++];
    if (!(u0 & 128)) {
      str += String.fromCharCode(u0);
      continue;
    }
    var u1 = heapOrArray[idx++] & 63;
    if ((u0 & 224) == 192) {
      str += String.fromCharCode(((u0 & 31) << 6) | u1);
      continue;
    }
    var u2 = heapOrArray[idx++] & 63;
    if ((u0 & 240) == 224) {
      u0 = ((u0 & 15) << 12) | (u1 << 6) | u2;
    } else {
      if ((u0 & 248) != 240) warnOnce(`Invalid UTF-8 leading byte ${ptrToString(u0)} encountered when deserializing a UTF-8 string in wasm memory to a JS string!`);
      u0 = ((u0 & 7) << 18) | (u1 << 12) | (u2 << 6) | (heapOrArray[idx++] & 63);
    }
    if (u0 < 65536) {
      str += String.fromCharCode(u0);
    } else {
      var ch = u0 - 65536;
      str += String.fromCharCode(55296 | (ch >> 10), 56320 | (ch & 1023));
    }
  }
  return str;
};

/**
   * Given a pointer 'ptr' to a null-terminated UTF8-encoded string in the
   * emscripten HEAP, returns a copy of that string as a Javascript String object.
   *
   * @param {number} ptr
   * @param {number=} maxBytesToRead - An optional length that specifies the
   *   maximum number of bytes to read. You can omit this parameter to scan the
   *   string until the first 0 byte. If maxBytesToRead is passed, and the string
   *   at [ptr, ptr+maxBytesToReadr[ contains a null byte in the middle, then the
   *   string will cut short at that byte index.
   * @param {boolean=} ignoreNul - If true, the function will not stop on a NUL character.
   * @return {string}
   */ var UTF8ToString = (ptr, maxBytesToRead, ignoreNul) => {
  assert(typeof ptr == "number", `UTF8ToString expects a number (got ${typeof ptr})`);
  return ptr ? UTF8ArrayToString(HEAPU8, ptr, maxBytesToRead, ignoreNul) : "";
};

var ___assert_fail = (condition, filename, line, func) => abort(`Assertion failed: ${UTF8ToString(condition)}, at: ` + [ filename ? UTF8ToString(filename) : "unknown filename", line, func ? UTF8ToString(func) : "unknown function" ]);

var wasmTableMirror = [];

var getWasmTableEntry = funcPtr => {
  var func = wasmTableMirror[funcPtr];
  if (!func) {
    /** @suppress {checkTypes} */ wasmTableMirror[funcPtr] = func = wasmTable.get(funcPtr);
  }
  /** @suppress {checkTypes} */ assert(wasmTable.get(funcPtr) == func, "JavaScript-side Wasm function table mirror is out of date!");
  return func;
};

var ___call_sighandler = (fp, sig) => getWasmTableEntry(fp)(sig);

class ExceptionInfo {
  // excPtr - Thrown object pointer to wrap. Metadata pointer is calculated from it.
  constructor(excPtr) {
    this.excPtr = excPtr;
    this.ptr = excPtr - 24;
  }
  set_type(type) {
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (4)) >> 2), "storing")] = type;
  }
  get_type() {
    return HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (4)) >> 2), "loading")];
  }
  set_destructor(destructor) {
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (8)) >> 2), "storing")] = destructor;
  }
  get_destructor() {
    return HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (8)) >> 2), "loading")];
  }
  set_caught(caught) {
    caught = caught ? 1 : 0;
    HEAP8[SAFE_HEAP_INDEX(HEAP8, (this.ptr) + (12), "storing")] = caught;
    checkInt8(caught);
  }
  get_caught() {
    return HEAP8[SAFE_HEAP_INDEX(HEAP8, (this.ptr) + (12), "loading")] != 0;
  }
  set_rethrown(rethrown) {
    rethrown = rethrown ? 1 : 0;
    HEAP8[SAFE_HEAP_INDEX(HEAP8, (this.ptr) + (13), "storing")] = rethrown;
    checkInt8(rethrown);
  }
  get_rethrown() {
    return HEAP8[SAFE_HEAP_INDEX(HEAP8, (this.ptr) + (13), "loading")] != 0;
  }
  // Initialize native structure fields. Should be called once after allocated.
  init(type, destructor) {
    this.set_adjusted_ptr(0);
    this.set_type(type);
    this.set_destructor(destructor);
  }
  set_adjusted_ptr(adjustedPtr) {
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (16)) >> 2), "storing")] = adjustedPtr;
  }
  get_adjusted_ptr() {
    return HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (16)) >> 2), "loading")];
  }
}

var uncaughtExceptionCount = 0;

var ___cxa_throw = (ptr, type, destructor) => {
  var info = new ExceptionInfo(ptr);
  // Initialize ExceptionInfo content after it was allocated in __cxa_allocate_exception.
  info.init(type, destructor);
  uncaughtExceptionCount++;
  assert(false, "Exception thrown, but exception catching is not enabled. Compile with -sNO_DISABLE_EXCEPTION_CATCHING or -sEXCEPTION_CATCHING_ALLOWED=[..] to catch.");
};

var ___handle_stack_overflow = requested => {
  var base = _emscripten_stack_get_base();
  var end = _emscripten_stack_get_end();
  abort(`stack overflow (Attempt to set SP to ${ptrToString(requested)}` + `, with stack limits [${ptrToString(end)} - ${ptrToString(base)}` + "]). If you require more stack space build with -sSTACK_SIZE=<bytes>");
};

var __abort_js = () => abort("native code called abort()");

var runtimeKeepaliveCounter = 0;

var __emscripten_runtime_keepalive_clear = () => {
  noExitRuntime = false;
  runtimeKeepaliveCounter = 0;
};

var _emscripten_get_now = () => performance.now();

var _emscripten_date_now = () => Date.now();

var nowIsMonotonic = 1;

var checkWasiClock = clock_id => clock_id >= 0 && clock_id <= 3;

var INT53_MAX = 9007199254740992;

var INT53_MIN = -9007199254740992;

var bigintToI53Checked = num => (num < INT53_MIN || num > INT53_MAX) ? NaN : Number(num);

function _clock_time_get(clk_id, ignored_precision, ptime) {
  ignored_precision = bigintToI53Checked(ignored_precision);
  if (!checkWasiClock(clk_id)) {
    return 28;
  }
  var now;
  // all wasi clocks but realtime are monotonic
  if (clk_id === 0) {
    now = _emscripten_date_now();
  } else if (nowIsMonotonic) {
    now = _emscripten_get_now();
  } else {
    return 52;
  }
  // "now" is in ms, and wasi times are in ns.
  var nsec = Math.round(now * 1e3 * 1e3);
  HEAP64[SAFE_HEAP_INDEX(HEAP64, ((ptime) >> 3), "storing")] = BigInt(nsec);
  checkInt64(nsec);
  return 0;
}

var getHeapMax = () => // Stay one Wasm page short of 4GB: while e.g. Chrome is able to allocate
// full 4GB Wasm memories, the size will wrap back to 0 bytes in Wasm side
// for any code that deals with heap sizes, which would require special
// casing all heap size related code to treat 0 specially.
2147483648;

var _emscripten_get_heap_max = () => getHeapMax();

var _emscripten_has_asyncify = () => 0;

var alignMemory = (size, alignment) => {
  assert(alignment, "alignment argument is required");
  return Math.ceil(size / alignment) * alignment;
};

var growMemory = size => {
  var oldHeapSize = wasmMemory.buffer.byteLength;
  var pages = ((size - oldHeapSize + 65535) / 65536) | 0;
  try {
    // round size grow request up to wasm page size (fixed 64KB per spec)
    wasmMemory.grow(pages);
    // .grow() takes a delta compared to the previous size
    updateMemoryViews();
    return 1;
  } catch (e) {
    err(`growMemory: Attempted to grow heap from ${oldHeapSize} bytes to ${size} bytes, but got error: ${e}`);
  }
};

var _emscripten_resize_heap = requestedSize => {
  var oldSize = HEAPU8.length;
  // With CAN_ADDRESS_2GB or MEMORY64, pointers are already unsigned.
  requestedSize >>>= 0;
  // With multithreaded builds, races can happen (another thread might increase the size
  // in between), so return a failure, and let the caller retry.
  assert(requestedSize > oldSize);
  // Memory resize rules:
  // 1.  Always increase heap size to at least the requested size, rounded up
  //     to next page multiple.
  // 2a. If MEMORY_GROWTH_LINEAR_STEP == -1, excessively resize the heap
  //     geometrically: increase the heap size according to
  //     MEMORY_GROWTH_GEOMETRIC_STEP factor (default +20%), At most
  //     overreserve by MEMORY_GROWTH_GEOMETRIC_CAP bytes (default 96MB).
  // 2b. If MEMORY_GROWTH_LINEAR_STEP != -1, excessively resize the heap
  //     linearly: increase the heap size by at least
  //     MEMORY_GROWTH_LINEAR_STEP bytes.
  // 3.  Max size for the heap is capped at 2048MB-WASM_PAGE_SIZE, or by
  //     MAXIMUM_MEMORY, or by ASAN limit, depending on which is smallest
  // 4.  If we were unable to allocate as much memory, it may be due to
  //     over-eager decision to excessively reserve due to (3) above.
  //     Hence if an allocation fails, cut down on the amount of excess
  //     growth, in an attempt to succeed to perform a smaller allocation.
  // A limit is set for how much we can grow. We should not exceed that
  // (the wasm binary specifies it, so if we tried, we'd fail anyhow).
  var maxHeapSize = getHeapMax();
  if (requestedSize > maxHeapSize) {
    err(`Cannot enlarge memory, requested ${requestedSize} bytes, but the limit is ${maxHeapSize} bytes!`);
    return false;
  }
  // Loop through potential heap size increases. If we attempt a too eager
  // reservation that fails, cut down on the attempted size and reserve a
  // smaller bump instead. (max 3 times, chosen somewhat arbitrarily)
  for (var cutDown = 1; cutDown <= 4; cutDown *= 2) {
    var overGrownHeapSize = oldSize * (1 + .2 / cutDown);
    // ensure geometric growth
    // but limit overreserving (default to capping at +96MB overgrowth at most)
    overGrownHeapSize = Math.min(overGrownHeapSize, requestedSize + 100663296);
    var newSize = Math.min(maxHeapSize, alignMemory(Math.max(requestedSize, overGrownHeapSize), 65536));
    var t0 = _emscripten_get_now();
    var replacement = growMemory(newSize);
    var t1 = _emscripten_get_now();
    dbg(`Heap resize call from ${oldSize} to ${newSize} took ${(t1 - t0)} msecs. Success: ${!!replacement}`);
    if (replacement) {
      return true;
    }
  }
  err(`Failed to grow the heap from ${oldSize} bytes to ${newSize} bytes, not enough memory!`);
  return false;
};

var handleException = e => {
  // Certain exception types we do not treat as errors since they are used for
  // internal control flow.
  // 1. ExitStatus, which is thrown by exit()
  // 2. "unwind", which is thrown by emscripten_unwind_to_js_event_loop() and others
  //    that wish to return to JS event loop.
  if (e instanceof ExitStatus || e == "unwind") {
    return EXITSTATUS;
  }
  checkStackCookie();
  if (e instanceof WebAssembly.RuntimeError) {
    if (_emscripten_stack_get_current() <= 0) {
      err("Stack overflow detected.  You can try increasing -sSTACK_SIZE (currently set to 4194304)");
    }
  }
  quit_(1, e);
};

var keepRuntimeAlive = () => noExitRuntime || runtimeKeepaliveCounter > 0;

var _proc_exit = code => {
  EXITSTATUS = code;
  if (!keepRuntimeAlive()) {
    Module["onExit"]?.(code);
    ABORT = true;
  }
  quit_(code, new ExitStatus(code));
};

/** @param {boolean|number=} implicit */ var exitJS = (status, implicit) => {
  EXITSTATUS = status;
  checkUnflushedContent();
  // if exit() was called explicitly, warn the user if the runtime isn't actually being shut down
  if (keepRuntimeAlive() && !implicit) {
    var msg = `program exited (with status: ${status}), but keepRuntimeAlive() is set (counter=${runtimeKeepaliveCounter}) due to an async operation, so halting execution but not exiting the runtime or preventing further async execution (you can use emscripten_force_exit, if you want to force a true shutdown)`;
    err(msg);
  }
  _proc_exit(status);
};

var _exit = exitJS;

var maybeExit = () => {
  if (!keepRuntimeAlive()) {
    try {
      _exit(EXITSTATUS);
    } catch (e) {
      handleException(e);
    }
  }
};

var callUserCallback = func => {
  if (ABORT) {
    err("user callback triggered after runtime exited or application aborted.  Ignoring.");
    return;
  }
  try {
    return func();
  } catch (e) {
    handleException(e);
  } finally {
    maybeExit();
  }
};

var _emscripten_set_main_loop_timing = (mode, value) => {
  MainLoop.timingMode = mode;
  MainLoop.timingValue = value;
  if (!MainLoop.func) {
    err("emscripten_set_main_loop_timing: Cannot set timing mode for main loop since a main loop does not exist! Call emscripten_set_main_loop first to set one up.");
    return 1;
  }
  if (!MainLoop.running) {
    MainLoop.running = true;
  }
  if (mode == 0) {
    MainLoop.scheduler = function MainLoop_scheduler_setTimeout() {
      var timeUntilNextTick = Math.max(0, MainLoop.tickStartTime + value - _emscripten_get_now()) | 0;
      setTimeout(MainLoop.runner, timeUntilNextTick);
    };
  } else if (mode == 1) {
    MainLoop.scheduler = function MainLoop_scheduler_rAF() {
      MainLoop.requestAnimationFrame(MainLoop.runner);
    };
  } else {
    assert(mode == 2);
    if (!MainLoop.setImmediate) {
      if (globalThis.setImmediate) {
        MainLoop.setImmediate = setImmediate;
      } else {
        // Emulate setImmediate. (note: not a complete polyfill, we don't emulate clearImmediate() to keep code size to minimum, since not needed)
        var setImmediates = [];
        var emscriptenMainLoopMessageId = "setimmediate";
        /** @param {Event} event */ var MainLoop_setImmediate_messageHandler = event => {
          // When called in current thread or Worker, the main loop ID is structured slightly different to accommodate for --proxy-to-worker runtime listening to Worker events,
          // so check for both cases.
          if (event.data === emscriptenMainLoopMessageId || event.data.target === emscriptenMainLoopMessageId) {
            event.stopPropagation();
            setImmediates.shift()();
          }
        };
        addEventListener("message", MainLoop_setImmediate_messageHandler, true);
        MainLoop.setImmediate = /** @type{function(function(): ?, ...?): number} */ (func => {
          setImmediates.push(func);
          if (ENVIRONMENT_IS_WORKER) {
            Module["setImmediates"] ??= [];
            Module["setImmediates"].push(func);
            postMessage({
              target: emscriptenMainLoopMessageId
            });
          } else postMessage(emscriptenMainLoopMessageId, "*");
        });
      }
    }
    MainLoop.scheduler = function MainLoop_scheduler_setImmediate() {
      MainLoop.setImmediate(MainLoop.runner);
    };
  }
  return 0;
};

var MainLoop = {
  running: false,
  scheduler: null,
  currentlyRunningMainloop: 0,
  func: null,
  arg: 0,
  timingMode: 0,
  timingValue: 0,
  currentFrameNumber: 0,
  queue: [],
  preMainLoop: [],
  postMainLoop: [],
  pause() {
    MainLoop.scheduler = null;
    // Incrementing this signals the previous main loop that it's now become old, and it must return.
    MainLoop.currentlyRunningMainloop++;
  },
  resume() {
    MainLoop.currentlyRunningMainloop++;
    var timingMode = MainLoop.timingMode;
    var timingValue = MainLoop.timingValue;
    var func = MainLoop.func;
    MainLoop.func = null;
    // do not set timing and call scheduler, we will do it on the next lines
    setMainLoop(func, 0, false, MainLoop.arg, true);
    _emscripten_set_main_loop_timing(timingMode, timingValue);
    MainLoop.scheduler();
  },
  updateStatus() {
    if (Module["setStatus"]) {
      var message = Module["statusMessage"] || "Please wait...";
      var remaining = MainLoop.remainingBlockers ?? 0;
      var expected = MainLoop.expectedBlockers ?? 0;
      if (remaining) {
        if (remaining < expected) {
          Module["setStatus"](`{message} ({expected - remaining}/{expected})`);
        } else {
          Module["setStatus"](message);
        }
      } else {
        Module["setStatus"]("");
      }
    }
  },
  init() {
    Module["preMainLoop"] && MainLoop.preMainLoop.push(Module["preMainLoop"]);
    Module["postMainLoop"] && MainLoop.postMainLoop.push(Module["postMainLoop"]);
  },
  runIter(func) {
    if (ABORT) return;
    for (var pre of MainLoop.preMainLoop) {
      if (pre() === false) {
        return;
      }
    }
    callUserCallback(func);
    for (var post of MainLoop.postMainLoop) {
      post();
    }
    checkStackCookie();
  },
  nextRAF: 0,
  fakeRequestAnimationFrame(func) {
    // try to keep 60fps between calls to here
    var now = Date.now();
    if (MainLoop.nextRAF === 0) {
      MainLoop.nextRAF = now + 1e3 / 60;
    } else {
      while (now + 2 >= MainLoop.nextRAF) {
        // fudge a little, to avoid timer jitter causing us to do lots of delay:0
        MainLoop.nextRAF += 1e3 / 60;
      }
    }
    var delay = Math.max(MainLoop.nextRAF - now, 0);
    setTimeout(func, delay);
  },
  requestAnimationFrame(func) {
    if (globalThis.requestAnimationFrame) {
      requestAnimationFrame(func);
    } else {
      MainLoop.fakeRequestAnimationFrame(func);
    }
  }
};

/**
   * @param {number=} arg
   * @param {boolean=} noSetTiming
   */ var setMainLoop = (iterFunc, fps, simulateInfiniteLoop, arg, noSetTiming) => {
  assert(!MainLoop.func, "emscripten_set_main_loop: there can only be one main loop function at once: call emscripten_cancel_main_loop to cancel the previous one before setting a new one with different parameters.");
  MainLoop.func = iterFunc;
  MainLoop.arg = arg;
  var thisMainLoopId = MainLoop.currentlyRunningMainloop;
  function checkIsRunning() {
    if (thisMainLoopId < MainLoop.currentlyRunningMainloop) {
      maybeExit();
      return false;
    }
    return true;
  }
  // We create the loop runner here but it is not actually running until
  // _emscripten_set_main_loop_timing is called (which might happen at a
  // later time).  This member signifies that the current runner has not
  // yet been started so that we can call runtimeKeepalivePush when it
  // gets its timing set for the first time.
  MainLoop.running = false;
  MainLoop.runner = function MainLoop_runner() {
    if (ABORT) return;
    if (MainLoop.queue.length > 0) {
      var start = Date.now();
      var blocker = MainLoop.queue.shift();
      blocker.func(blocker.arg);
      if (MainLoop.remainingBlockers) {
        var remaining = MainLoop.remainingBlockers;
        var next = remaining % 1 == 0 ? remaining - 1 : Math.floor(remaining);
        if (blocker.counted) {
          MainLoop.remainingBlockers = next;
        } else {
          // not counted, but move the progress along a tiny bit
          next = next + .5;
          // do not steal all the next one's progress
          MainLoop.remainingBlockers = (8 * remaining + next) / 9;
        }
      }
      MainLoop.updateStatus();
      // catches pause/resume main loop from blocker execution
      if (!checkIsRunning()) return;
      setTimeout(MainLoop.runner, 0);
      return;
    }
    // catch pauses from non-main loop sources
    if (!checkIsRunning()) return;
    // Implement very basic swap interval control
    MainLoop.currentFrameNumber = MainLoop.currentFrameNumber + 1 | 0;
    if (MainLoop.timingMode == 1 && MainLoop.timingValue > 1 && MainLoop.currentFrameNumber % MainLoop.timingValue != 0) {
      // Not the scheduled time to render this frame - skip.
      MainLoop.scheduler();
      return;
    } else if (MainLoop.timingMode == 0) {
      MainLoop.tickStartTime = _emscripten_get_now();
      if (Module["ctx"]) {
        warnOnce("Looks like you are rendering without using requestAnimationFrame for the main loop. You should use 0 for the frame rate in emscripten_set_main_loop in order to use requestAnimationFrame, as that can greatly improve your frame rates!");
      }
    }
    MainLoop.runIter(iterFunc);
    // catch pauses from the main loop itself
    if (!checkIsRunning()) return;
    MainLoop.scheduler();
  };
  if (!noSetTiming) {
    if (fps > 0) {
      _emscripten_set_main_loop_timing(0, 1e3 / fps);
    } else {
      // Do rAF by rendering each frame (no decimating)
      _emscripten_set_main_loop_timing(1, 1);
    }
    MainLoop.scheduler();
  }
  if (simulateInfiniteLoop) {
    throw "unwind";
  }
};

var _emscripten_set_main_loop = (func, fps, simulateInfiniteLoop) => {
  var iterFunc = getWasmTableEntry(func);
  setMainLoop(iterFunc, fps, simulateInfiniteLoop);
};

var lengthBytesUTF8 = str => {
  var len = 0;
  for (var i = 0; i < str.length; ++i) {
    // Gotcha: charCodeAt returns a 16-bit word that is a UTF-16 encoded code
    // unit, not a Unicode code point of the character! So decode
    // UTF16->UTF32->UTF8.
    // See http://unicode.org/faq/utf_bom.html#utf16-3
    var c = str.charCodeAt(i);
    // possibly a lead surrogate
    if (c <= 127) {
      len++;
    } else if (c <= 2047) {
      len += 2;
    } else if (c >= 55296 && c <= 57343) {
      len += 4;
      ++i;
    } else {
      len += 3;
    }
  }
  return len;
};

var stringToUTF8Array = (str, heap, outIdx, maxBytesToWrite) => {
  assert(typeof str === "string", `stringToUTF8Array expects a string (got ${typeof str})`);
  // Parameter maxBytesToWrite is not optional. Negative values, 0, null,
  // undefined and false each don't write out any bytes.
  if (!(maxBytesToWrite > 0)) return 0;
  var startIdx = outIdx;
  var endIdx = outIdx + maxBytesToWrite - 1;
  // -1 for string null terminator.
  for (var i = 0; i < str.length; ++i) {
    // For UTF8 byte structure, see http://en.wikipedia.org/wiki/UTF-8#Description
    // and https://www.ietf.org/rfc/rfc2279.txt
    // and https://tools.ietf.org/html/rfc3629
    var u = str.codePointAt(i);
    if (u <= 127) {
      if (outIdx >= endIdx) break;
      heap[outIdx++] = u;
    } else if (u <= 2047) {
      if (outIdx + 1 >= endIdx) break;
      heap[outIdx++] = 192 | (u >> 6);
      heap[outIdx++] = 128 | (u & 63);
    } else if (u <= 65535) {
      if (outIdx + 2 >= endIdx) break;
      heap[outIdx++] = 224 | (u >> 12);
      heap[outIdx++] = 128 | ((u >> 6) & 63);
      heap[outIdx++] = 128 | (u & 63);
    } else {
      if (outIdx + 3 >= endIdx) break;
      if (u > 1114111) warnOnce(`Invalid Unicode code point ${ptrToString(u)} encountered when serializing a JS string to a UTF-8 string in wasm memory! (Valid unicode code points should be in range 0-0x10FFFF).`);
      heap[outIdx++] = 240 | (u >> 18);
      heap[outIdx++] = 128 | ((u >> 12) & 63);
      heap[outIdx++] = 128 | ((u >> 6) & 63);
      heap[outIdx++] = 128 | (u & 63);
      // Gotcha: if codePoint is over 0xFFFF, it is represented as a surrogate pair in UTF-16.
      // We need to manually skip over the second code unit for correct iteration.
      i++;
    }
  }
  // Null-terminate the pointer to the buffer.
  heap[outIdx] = 0;
  return outIdx - startIdx;
};

var stringToUTF8 = (str, outPtr, maxBytesToWrite) => {
  assert(typeof maxBytesToWrite == "number", "stringToUTF8(str, outPtr, maxBytesToWrite) is missing the third parameter that specifies the length of the output buffer!");
  return stringToUTF8Array(str, HEAPU8, outPtr, maxBytesToWrite);
};

var stackAlloc = sz => __emscripten_stack_alloc(sz);

var stringToUTF8OnStack = str => {
  var size = lengthBytesUTF8(str) + 1;
  var ret = stackAlloc(size);
  stringToUTF8(str, ret, size);
  return ret;
};

var stringToNewUTF8 = str => {
  var size = lengthBytesUTF8(str) + 1;
  var ret = _malloc(size);
  if (ret) stringToUTF8(str, ret, size);
  return ret;
};

var WebGPU = {
  Internals: {
    jsObjects: [],
    jsObjectInsert: (ptr, jsObject) => {
      ptr >>>= 0;
      WebGPU.Internals.jsObjects[ptr] = jsObject;
    },
    bufferOnUnmaps: [],
    futures: [],
    futureInsert: (futureId, promise) => {}
  },
  getJsObject: ptr => {
    if (!ptr) return undefined;
    ptr >>>= 0;
    assert(ptr in WebGPU.Internals.jsObjects);
    return WebGPU.Internals.jsObjects[ptr];
  },
  importJsAdapter: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateAdapter(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsBindGroup: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateBindGroup(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsBindGroupLayout: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateBindGroupLayout(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsBuffer: (buffer, parentPtr = 0) => {
    // At the moment, we do not allow importing pending buffers.
    assert(buffer.mapState != "pending");
    var mapState = buffer.mapState == "mapped" ? 3 : 1;
    var bufferPtr = _emwgpuCreateBuffer(parentPtr, mapState);
    WebGPU.Internals.jsObjectInsert(bufferPtr, buffer);
    if (buffer.mapState == "mapped") {
      WebGPU.Internals.bufferOnUnmaps[bufferPtr] = [];
    }
    return bufferPtr;
  },
  importJsCommandBuffer: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateCommandBuffer(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsCommandEncoder: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateCommandEncoder(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsComputePassEncoder: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateComputePassEncoder(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsComputePipeline: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateComputePipeline(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsDevice: (device, parentPtr = 0) => {
    var queuePtr = _emwgpuCreateQueue(parentPtr);
    var devicePtr = _emwgpuCreateDevice(parentPtr, queuePtr);
    WebGPU.Internals.jsObjectInsert(queuePtr, device.queue);
    WebGPU.Internals.jsObjectInsert(devicePtr, device);
    return devicePtr;
  },
  importJsPipelineLayout: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreatePipelineLayout(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsQuerySet: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateQuerySet(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsQueue: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateQueue(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsRenderBundle: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateRenderBundle(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsRenderBundleEncoder: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateRenderBundleEncoder(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsRenderPassEncoder: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateRenderPassEncoder(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsRenderPipeline: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateRenderPipeline(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsSampler: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateSampler(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsShaderModule: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateShaderModule(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsSurface: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateSurface(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsTexture: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateTexture(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  importJsTextureView: (obj, parentPtr = 0) => {
    var ptr = _emwgpuCreateTextureView(parentPtr);
    WebGPU.Internals.jsObjects[ptr] = obj;
    return ptr;
  },
  errorCallback: (callback, type, message, userdata) => {
    var sp = stackSave();
    var messagePtr = stringToUTF8OnStack(message);
    getWasmTableEntry(callback)(type, messagePtr, userdata);
    stackRestore(sp);
  },
  setStringView: (ptr, data, length) => {
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "storing")] = data;
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (4)) >> 2), "storing")] = length;
  },
  makeStringFromStringView: stringViewPtr => {
    var ptr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((stringViewPtr) >> 2), "loading")];
    var length = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((stringViewPtr) + (4)) >> 2), "loading")];
    // UTF8ToString stops at the first null terminator character in the
    // string regardless of the length.
    return UTF8ToString(ptr, length);
  },
  makeStringFromOptionalStringView: stringViewPtr => {
    var ptr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((stringViewPtr) >> 2), "loading")];
    var length = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((stringViewPtr) + (4)) >> 2), "loading")];
    // If we don't have a valid string pointer, just return undefined when
    // optional.
    if (!ptr) {
      if (length === 0) {
        return "";
      }
      return undefined;
    }
    // UTF8ToString stops at the first null terminator character in the
    // string regardless of the length.
    return UTF8ToString(ptr, length);
  },
  makeColor: ptr => ({
    "r": HEAPF64[SAFE_HEAP_INDEX(HEAPF64, ((ptr) >> 3), "loading")],
    "g": HEAPF64[SAFE_HEAP_INDEX(HEAPF64, (((ptr) + (8)) >> 3), "loading")],
    "b": HEAPF64[SAFE_HEAP_INDEX(HEAPF64, (((ptr) + (16)) >> 3), "loading")],
    "a": HEAPF64[SAFE_HEAP_INDEX(HEAPF64, (((ptr) + (24)) >> 3), "loading")]
  }),
  makeExtent3D: ptr => ({
    "width": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")],
    "height": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (4)) >> 2), "loading")],
    "depthOrArrayLayers": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (8)) >> 2), "loading")]
  }),
  makeOrigin3D: ptr => ({
    "x": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")],
    "y": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (4)) >> 2), "loading")],
    "z": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (8)) >> 2), "loading")]
  }),
  makeTexelCopyTextureInfo: ptr => {
    assert(ptr);
    return {
      "texture": WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")]),
      "mipLevel": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (4)) >> 2), "loading")],
      "origin": WebGPU.makeOrigin3D(ptr + 8),
      "aspect": WebGPU.TextureAspect[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (20)) >> 2), "loading")]]
    };
  },
  makeTexelCopyBufferLayout: ptr => {
    var bytesPerRow = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (8)) >> 2), "loading")];
    var rowsPerImage = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (12)) >> 2), "loading")];
    return {
      "offset": (HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr + 4)) >> 2), "loading")] * 4294967296 + HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")]),
      "bytesPerRow": bytesPerRow === 4294967295 ? undefined : bytesPerRow,
      "rowsPerImage": rowsPerImage === 4294967295 ? undefined : rowsPerImage
    };
  },
  makeTexelCopyBufferInfo: ptr => {
    assert(ptr);
    var layoutPtr = ptr + 0;
    var bufferCopyView = WebGPU.makeTexelCopyBufferLayout(layoutPtr);
    bufferCopyView["buffer"] = WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (16)) >> 2), "loading")]);
    return bufferCopyView;
  },
  makePassTimestampWrites: ptr => {
    if (ptr === 0) return undefined;
    return {
      "querySet": WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (4)) >> 2), "loading")]),
      "beginningOfPassWriteIndex": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (8)) >> 2), "loading")],
      "endOfPassWriteIndex": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (12)) >> 2), "loading")]
    };
  },
  makePipelineConstants: (constantCount, constantsPtr) => {
    if (!constantCount) return;
    var constants = {};
    for (var i = 0; i < constantCount; ++i) {
      var entryPtr = constantsPtr + 24 * i;
      var key = WebGPU.makeStringFromStringView(entryPtr + 4);
      constants[key] = HEAPF64[SAFE_HEAP_INDEX(HEAPF64, (((entryPtr) + (16)) >> 3), "loading")];
    }
    return constants;
  },
  makePipelineLayout: layoutPtr => {
    if (!layoutPtr) return "auto";
    return WebGPU.getJsObject(layoutPtr);
  },
  makeComputeState: ptr => {
    if (!ptr) return undefined;
    assert(ptr);
    assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")] === 0);
    var desc = {
      "module": WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (4)) >> 2), "loading")]),
      "constants": WebGPU.makePipelineConstants(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (16)) >> 2), "loading")], HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (20)) >> 2), "loading")]),
      "entryPoint": WebGPU.makeStringFromOptionalStringView(ptr + 8)
    };
    return desc;
  },
  makeComputePipelineDesc: descriptor => {
    assert(descriptor);
    assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")] === 0);
    var desc = {
      "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4),
      "layout": WebGPU.makePipelineLayout(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (12)) >> 2), "loading")]),
      "compute": WebGPU.makeComputeState(descriptor + 16)
    };
    return desc;
  },
  makeRenderPipelineDesc: descriptor => {
    assert(descriptor);
    assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")] === 0);
    function makePrimitiveState(psPtr) {
      if (!psPtr) return undefined;
      assert(psPtr);
      assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((psPtr) >> 2), "loading")] === 0);
      return {
        "topology": WebGPU.PrimitiveTopology[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((psPtr) + (4)) >> 2), "loading")]],
        "stripIndexFormat": WebGPU.IndexFormat[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((psPtr) + (8)) >> 2), "loading")]],
        "frontFace": WebGPU.FrontFace[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((psPtr) + (12)) >> 2), "loading")]],
        "cullMode": WebGPU.CullMode[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((psPtr) + (16)) >> 2), "loading")]],
        "unclippedDepth": !!(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((psPtr) + (20)) >> 2), "loading")])
      };
    }
    function makeBlendComponent(bdPtr) {
      if (!bdPtr) return undefined;
      return {
        "operation": WebGPU.BlendOperation[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((bdPtr) >> 2), "loading")]],
        "srcFactor": WebGPU.BlendFactor[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((bdPtr) + (4)) >> 2), "loading")]],
        "dstFactor": WebGPU.BlendFactor[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((bdPtr) + (8)) >> 2), "loading")]]
      };
    }
    function makeBlendState(bsPtr) {
      if (!bsPtr) return undefined;
      return {
        "alpha": makeBlendComponent(bsPtr + 12),
        "color": makeBlendComponent(bsPtr + 0)
      };
    }
    function makeColorState(csPtr) {
      assert(csPtr);
      assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((csPtr) >> 2), "loading")] === 0);
      var formatInt = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((csPtr) + (4)) >> 2), "loading")];
      return formatInt === 0 ? undefined : {
        "format": WebGPU.TextureFormat[formatInt],
        "blend": makeBlendState(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((csPtr) + (8)) >> 2), "loading")]),
        "writeMask": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((csPtr) + (16)) >> 2), "loading")]
      };
    }
    function makeColorStates(count, csArrayPtr) {
      var states = [];
      for (var i = 0; i < count; ++i) {
        states.push(makeColorState(csArrayPtr + 24 * i));
      }
      return states;
    }
    function makeStencilStateFace(ssfPtr) {
      assert(ssfPtr);
      return {
        "compare": WebGPU.CompareFunction[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ssfPtr) >> 2), "loading")]],
        "failOp": WebGPU.StencilOperation[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ssfPtr) + (4)) >> 2), "loading")]],
        "depthFailOp": WebGPU.StencilOperation[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ssfPtr) + (8)) >> 2), "loading")]],
        "passOp": WebGPU.StencilOperation[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ssfPtr) + (12)) >> 2), "loading")]]
      };
    }
    function makeDepthStencilState(dssPtr) {
      if (!dssPtr) return undefined;
      assert(dssPtr);
      return {
        "format": WebGPU.TextureFormat[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dssPtr) + (4)) >> 2), "loading")]],
        "depthWriteEnabled": !!(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dssPtr) + (8)) >> 2), "loading")]),
        "depthCompare": WebGPU.CompareFunction[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dssPtr) + (12)) >> 2), "loading")]],
        "stencilFront": makeStencilStateFace(dssPtr + 16),
        "stencilBack": makeStencilStateFace(dssPtr + 32),
        "stencilReadMask": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dssPtr) + (48)) >> 2), "loading")],
        "stencilWriteMask": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dssPtr) + (52)) >> 2), "loading")],
        "depthBias": HEAP32[SAFE_HEAP_INDEX(HEAP32, (((dssPtr) + (56)) >> 2), "loading")],
        "depthBiasSlopeScale": HEAPF32[SAFE_HEAP_INDEX(HEAPF32, (((dssPtr) + (60)) >> 2), "loading")],
        "depthBiasClamp": HEAPF32[SAFE_HEAP_INDEX(HEAPF32, (((dssPtr) + (64)) >> 2), "loading")]
      };
    }
    function makeVertexAttribute(vaPtr) {
      assert(vaPtr);
      return {
        "format": WebGPU.VertexFormat[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((vaPtr) + (4)) >> 2), "loading")]],
        "offset": (HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((((vaPtr + 4)) + (8)) >> 2), "loading")] * 4294967296 + HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((vaPtr) + (8)) >> 2), "loading")]),
        "shaderLocation": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((vaPtr) + (16)) >> 2), "loading")]
      };
    }
    function makeVertexAttributes(count, vaArrayPtr) {
      var vas = [];
      for (var i = 0; i < count; ++i) {
        vas.push(makeVertexAttribute(vaArrayPtr + i * 24));
      }
      return vas;
    }
    function makeVertexBuffer(vbPtr) {
      if (!vbPtr) return undefined;
      var stepModeInt = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((vbPtr) + (4)) >> 2), "loading")];
      var attributeCountInt = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((vbPtr) + (16)) >> 2), "loading")];
      if (stepModeInt === 0 && attributeCountInt === 0) {
        return null;
      }
      return {
        "arrayStride": (HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((((vbPtr + 4)) + (8)) >> 2), "loading")] * 4294967296 + HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((vbPtr) + (8)) >> 2), "loading")]),
        "stepMode": WebGPU.VertexStepMode[stepModeInt],
        "attributes": makeVertexAttributes(attributeCountInt, HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((vbPtr) + (20)) >> 2), "loading")])
      };
    }
    function makeVertexBuffers(count, vbArrayPtr) {
      if (!count) return undefined;
      var vbs = [];
      for (var i = 0; i < count; ++i) {
        vbs.push(makeVertexBuffer(vbArrayPtr + i * 24));
      }
      return vbs;
    }
    function makeVertexState(viPtr) {
      if (!viPtr) return undefined;
      assert(viPtr);
      assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((viPtr) >> 2), "loading")] === 0);
      var desc = {
        "module": WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((viPtr) + (4)) >> 2), "loading")]),
        "constants": WebGPU.makePipelineConstants(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((viPtr) + (16)) >> 2), "loading")], HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((viPtr) + (20)) >> 2), "loading")]),
        "buffers": makeVertexBuffers(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((viPtr) + (24)) >> 2), "loading")], HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((viPtr) + (28)) >> 2), "loading")]),
        "entryPoint": WebGPU.makeStringFromOptionalStringView(viPtr + 8)
      };
      return desc;
    }
    function makeMultisampleState(msPtr) {
      if (!msPtr) return undefined;
      assert(msPtr);
      assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((msPtr) >> 2), "loading")] === 0);
      return {
        "count": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((msPtr) + (4)) >> 2), "loading")],
        "mask": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((msPtr) + (8)) >> 2), "loading")],
        "alphaToCoverageEnabled": !!(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((msPtr) + (12)) >> 2), "loading")])
      };
    }
    function makeFragmentState(fsPtr) {
      if (!fsPtr) return undefined;
      assert(fsPtr);
      assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((fsPtr) >> 2), "loading")] === 0);
      var desc = {
        "module": WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((fsPtr) + (4)) >> 2), "loading")]),
        "constants": WebGPU.makePipelineConstants(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((fsPtr) + (16)) >> 2), "loading")], HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((fsPtr) + (20)) >> 2), "loading")]),
        "targets": makeColorStates(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((fsPtr) + (24)) >> 2), "loading")], HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((fsPtr) + (28)) >> 2), "loading")]),
        "entryPoint": WebGPU.makeStringFromOptionalStringView(fsPtr + 8)
      };
      return desc;
    }
    var desc = {
      "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4),
      "layout": WebGPU.makePipelineLayout(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (12)) >> 2), "loading")]),
      "vertex": makeVertexState(descriptor + 16),
      "primitive": makePrimitiveState(descriptor + 48),
      "depthStencil": makeDepthStencilState(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (72)) >> 2), "loading")]),
      "multisample": makeMultisampleState(descriptor + 76),
      "fragment": makeFragmentState(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (92)) >> 2), "loading")])
    };
    return desc;
  },
  fillLimitStruct: (limits, limitsOutPtr) => {
    assert(limitsOutPtr);
    assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((limitsOutPtr) >> 2), "loading")] === 0);
    function setLimitValueU32(name, limitOffset) {
      var limitValue = limits[name];
      HEAP32[SAFE_HEAP_INDEX(HEAP32, (((limitsOutPtr) + (limitOffset)) >> 2), "storing")] = limitValue;
      checkInt32(limitValue);
    }
    function setLimitValueU64(name, limitOffset) {
      var limitValue = limits[name];
      HEAP64[SAFE_HEAP_INDEX(HEAP64, (((limitsOutPtr) + (limitOffset)) >> 3), "storing")] = BigInt(limitValue);
      checkInt64(limitValue);
    }
    setLimitValueU32("maxTextureDimension1D", 4);
    setLimitValueU32("maxTextureDimension2D", 8);
    setLimitValueU32("maxTextureDimension3D", 12);
    setLimitValueU32("maxTextureArrayLayers", 16);
    setLimitValueU32("maxBindGroups", 20);
    setLimitValueU32("maxBindGroupsPlusVertexBuffers", 24);
    setLimitValueU32("maxBindingsPerBindGroup", 28);
    setLimitValueU32("maxDynamicUniformBuffersPerPipelineLayout", 32);
    setLimitValueU32("maxDynamicStorageBuffersPerPipelineLayout", 36);
    setLimitValueU32("maxSampledTexturesPerShaderStage", 40);
    setLimitValueU32("maxSamplersPerShaderStage", 44);
    setLimitValueU32("maxStorageBuffersPerShaderStage", 48);
    setLimitValueU32("maxStorageTexturesPerShaderStage", 52);
    setLimitValueU32("maxUniformBuffersPerShaderStage", 56);
    setLimitValueU32("minUniformBufferOffsetAlignment", 80);
    setLimitValueU32("minStorageBufferOffsetAlignment", 84);
    setLimitValueU64("maxUniformBufferBindingSize", 64);
    setLimitValueU64("maxStorageBufferBindingSize", 72);
    setLimitValueU32("maxVertexBuffers", 88);
    setLimitValueU64("maxBufferSize", 96);
    setLimitValueU32("maxVertexAttributes", 104);
    setLimitValueU32("maxVertexBufferArrayStride", 108);
    setLimitValueU32("maxInterStageShaderVariables", 112);
    setLimitValueU32("maxColorAttachments", 116);
    setLimitValueU32("maxColorAttachmentBytesPerSample", 120);
    setLimitValueU32("maxComputeWorkgroupStorageSize", 124);
    setLimitValueU32("maxComputeInvocationsPerWorkgroup", 128);
    setLimitValueU32("maxComputeWorkgroupSizeX", 132);
    setLimitValueU32("maxComputeWorkgroupSizeY", 136);
    setLimitValueU32("maxComputeWorkgroupSizeZ", 140);
    setLimitValueU32("maxComputeWorkgroupsPerDimension", 144);
    // Non-standard. If this is undefined, it will correctly just cast to 0.
    if (limits.maxImmediateSize !== undefined) {
      setLimitValueU32("maxImmediateSize", 148);
    }
  },
  fillAdapterInfoStruct: (info, infoStruct) => {
    assert(infoStruct);
    assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((infoStruct) >> 2), "loading")] === 0);
    // Populate subgroup limits.
    HEAP32[SAFE_HEAP_INDEX(HEAP32, (((infoStruct) + (52)) >> 2), "storing")] = info.subgroupMinSize;
    checkInt32(info.subgroupMinSize);
    HEAP32[SAFE_HEAP_INDEX(HEAP32, (((infoStruct) + (56)) >> 2), "storing")] = info.subgroupMaxSize;
    checkInt32(info.subgroupMaxSize);
    // Append all the strings together to condense into a single malloc.
    var strs = info.vendor + info.architecture + info.device + info.description;
    var strPtr = stringToNewUTF8(strs);
    var vendorLen = lengthBytesUTF8(info.vendor);
    WebGPU.setStringView(infoStruct + 4, strPtr, vendorLen);
    strPtr += vendorLen;
    var architectureLen = lengthBytesUTF8(info.architecture);
    WebGPU.setStringView(infoStruct + 12, strPtr, architectureLen);
    strPtr += architectureLen;
    var deviceLen = lengthBytesUTF8(info.device);
    WebGPU.setStringView(infoStruct + 20, strPtr, deviceLen);
    strPtr += deviceLen;
    var descriptionLen = lengthBytesUTF8(info.description);
    WebGPU.setStringView(infoStruct + 28, strPtr, descriptionLen);
    strPtr += descriptionLen;
    HEAP32[SAFE_HEAP_INDEX(HEAP32, (((infoStruct) + (36)) >> 2), "storing")] = 2;
    checkInt32(2);
    var adapterType = info.isFallbackAdapter ? 3 : 4;
    HEAP32[SAFE_HEAP_INDEX(HEAP32, (((infoStruct) + (40)) >> 2), "storing")] = adapterType;
    checkInt32(adapterType);
    HEAP32[SAFE_HEAP_INDEX(HEAP32, (((infoStruct) + (44)) >> 2), "storing")] = 0;
    checkInt32(0);
    HEAP32[SAFE_HEAP_INDEX(HEAP32, (((infoStruct) + (48)) >> 2), "storing")] = 0;
    checkInt32(0);
  },
  AddressMode: [ , "clamp-to-edge", "repeat", "mirror-repeat" ],
  BlendFactor: [ , "zero", "one", "src", "one-minus-src", "src-alpha", "one-minus-src-alpha", "dst", "one-minus-dst", "dst-alpha", "one-minus-dst-alpha", "src-alpha-saturated", "constant", "one-minus-constant", "src1", "one-minus-src1", "src1alpha", "one-minus-src1alpha" ],
  BlendOperation: [ , "add", "subtract", "reverse-subtract", "min", "max" ],
  BufferBindingType: [ "binding-not-used", , "uniform", "storage", "read-only-storage" ],
  BufferMapState: [ , "unmapped", "pending", "mapped" ],
  CompareFunction: [ , "never", "less", "equal", "less-equal", "greater", "not-equal", "greater-equal", "always" ],
  CompilationInfoRequestStatus: [ , "success", "callback-cancelled" ],
  CompositeAlphaMode: [ , "opaque", "premultiplied", "unpremultiplied", "inherit" ],
  CullMode: [ , "none", "front", "back" ],
  ErrorFilter: [ , "validation", "out-of-memory", "internal" ],
  FeatureLevel: [ , "compatibility", "core" ],
  FeatureName: {
    1: "core-features-and-limits",
    2: "depth-clip-control",
    3: "depth32float-stencil8",
    4: "texture-compression-bc",
    5: "texture-compression-bc-sliced-3d",
    6: "texture-compression-etc2",
    7: "texture-compression-astc",
    8: "texture-compression-astc-sliced-3d",
    9: "timestamp-query",
    10: "indirect-first-instance",
    11: "shader-f16",
    12: "rg11b10ufloat-renderable",
    13: "bgra8unorm-storage",
    14: "float32-filterable",
    15: "float32-blendable",
    16: "clip-distances",
    17: "dual-source-blending",
    18: "subgroups",
    19: "texture-formats-tier1",
    20: "texture-formats-tier2",
    21: "primitive-index",
    327692: "chromium-experimental-unorm16-texture-formats",
    327693: "chromium-experimental-snorm16-texture-formats",
    327732: "chromium-experimental-multi-draw-indirect"
  },
  FilterMode: [ , "nearest", "linear" ],
  FrontFace: [ , "ccw", "cw" ],
  IndexFormat: [ , "uint16", "uint32" ],
  InstanceFeatureName: [ , "timed-wait-any", "shader-source-spirv", "multiple-devices-per-adapter" ],
  LoadOp: [ , "load", "clear" ],
  MipmapFilterMode: [ , "nearest", "linear" ],
  OptionalBool: [ "false", "true" ],
  PowerPreference: [ , "low-power", "high-performance" ],
  PredefinedColorSpace: [ , "srgb", "display-p3" ],
  PrimitiveTopology: [ , "point-list", "line-list", "line-strip", "triangle-list", "triangle-strip" ],
  QueryType: [ , "occlusion", "timestamp" ],
  SamplerBindingType: [ "binding-not-used", , "filtering", "non-filtering", "comparison" ],
  Status: [ , "success", "error" ],
  StencilOperation: [ , "keep", "zero", "replace", "invert", "increment-clamp", "decrement-clamp", "increment-wrap", "decrement-wrap" ],
  StorageTextureAccess: [ "binding-not-used", , "write-only", "read-only", "read-write" ],
  StoreOp: [ , "store", "discard" ],
  SurfaceGetCurrentTextureStatus: [ , "success-optimal", "success-suboptimal", "timeout", "outdated", "lost", "error" ],
  TextureAspect: [ , "all", "stencil-only", "depth-only" ],
  TextureDimension: [ , "1d", "2d", "3d" ],
  TextureFormat: [ , "r8unorm", "r8snorm", "r8uint", "r8sint", "r16unorm", "r16snorm", "r16uint", "r16sint", "r16float", "rg8unorm", "rg8snorm", "rg8uint", "rg8sint", "r32float", "r32uint", "r32sint", "rg16unorm", "rg16snorm", "rg16uint", "rg16sint", "rg16float", "rgba8unorm", "rgba8unorm-srgb", "rgba8snorm", "rgba8uint", "rgba8sint", "bgra8unorm", "bgra8unorm-srgb", "rgb10a2uint", "rgb10a2unorm", "rg11b10ufloat", "rgb9e5ufloat", "rg32float", "rg32uint", "rg32sint", "rgba16unorm", "rgba16snorm", "rgba16uint", "rgba16sint", "rgba16float", "rgba32float", "rgba32uint", "rgba32sint", "stencil8", "depth16unorm", "depth24plus", "depth24plus-stencil8", "depth32float", "depth32float-stencil8", "bc1-rgba-unorm", "bc1-rgba-unorm-srgb", "bc2-rgba-unorm", "bc2-rgba-unorm-srgb", "bc3-rgba-unorm", "bc3-rgba-unorm-srgb", "bc4-r-unorm", "bc4-r-snorm", "bc5-rg-unorm", "bc5-rg-snorm", "bc6h-rgb-ufloat", "bc6h-rgb-float", "bc7-rgba-unorm", "bc7-rgba-unorm-srgb", "etc2-rgb8unorm", "etc2-rgb8unorm-srgb", "etc2-rgb8a1unorm", "etc2-rgb8a1unorm-srgb", "etc2-rgba8unorm", "etc2-rgba8unorm-srgb", "eac-r11unorm", "eac-r11snorm", "eac-rg11unorm", "eac-rg11snorm", "astc-4x4-unorm", "astc-4x4-unorm-srgb", "astc-5x4-unorm", "astc-5x4-unorm-srgb", "astc-5x5-unorm", "astc-5x5-unorm-srgb", "astc-6x5-unorm", "astc-6x5-unorm-srgb", "astc-6x6-unorm", "astc-6x6-unorm-srgb", "astc-8x5-unorm", "astc-8x5-unorm-srgb", "astc-8x6-unorm", "astc-8x6-unorm-srgb", "astc-8x8-unorm", "astc-8x8-unorm-srgb", "astc-10x5-unorm", "astc-10x5-unorm-srgb", "astc-10x6-unorm", "astc-10x6-unorm-srgb", "astc-10x8-unorm", "astc-10x8-unorm-srgb", "astc-10x10-unorm", "astc-10x10-unorm-srgb", "astc-12x10-unorm", "astc-12x10-unorm-srgb", "astc-12x12-unorm", "astc-12x12-unorm-srgb" ],
  TextureSampleType: [ "binding-not-used", , "float", "unfilterable-float", "depth", "sint", "uint" ],
  TextureViewDimension: [ , "1d", "2d", "2d-array", "cube", "cube-array", "3d" ],
  ToneMappingMode: [ , "standard", "extended" ],
  VertexFormat: [ , "uint8", "uint8x2", "uint8x4", "sint8", "sint8x2", "sint8x4", "unorm8", "unorm8x2", "unorm8x4", "snorm8", "snorm8x2", "snorm8x4", "uint16", "uint16x2", "uint16x4", "sint16", "sint16x2", "sint16x4", "unorm16", "unorm16x2", "unorm16x4", "snorm16", "snorm16x2", "snorm16x4", "float16", "float16x2", "float16x4", "float32", "float32x2", "float32x3", "float32x4", "uint32", "uint32x2", "uint32x3", "uint32x4", "sint32", "sint32x2", "sint32x3", "sint32x4", "unorm10-10-10-2", "unorm8x4-bgra" ],
  VertexStepMode: [ , "vertex", "instance" ],
  WGSLLanguageFeatureName: [ , "readonly_and_readwrite_storage_textures", "packed_4x8_integer_dot_product", "unrestricted_pointer_parameters", "pointer_composite_access" ]
};

var emwgpuStringToInt_DeviceLostReason = {
  "undefined": 1,
  // For older browsers
  "unknown": 1,
  "destroyed": 2
};

function _emwgpuAdapterRequestDevice(adapterPtr, futureId, deviceLostFutureId, devicePtr, queuePtr, descriptor) {
  futureId = bigintToI53Checked(futureId);
  deviceLostFutureId = bigintToI53Checked(deviceLostFutureId);
  var adapter = WebGPU.getJsObject(adapterPtr);
  var desc = {};
  if (descriptor) {
    assert(descriptor);
    assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")] === 0);
    var requiredFeatureCount = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (12)) >> 2), "loading")];
    if (requiredFeatureCount) {
      var requiredFeaturesPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (16)) >> 2), "loading")];
      // requiredFeaturesPtr is a pointer to an array of FeatureName which is an enum of size uint32_t
      desc["requiredFeatures"] = Array.from(HEAPU32.subarray((((requiredFeaturesPtr) >> 2)), ((requiredFeaturesPtr + requiredFeatureCount * 4) >> 2)), feature => WebGPU.FeatureName[feature]);
    }
    var limitsPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (20)) >> 2), "loading")];
    if (limitsPtr) {
      assert(limitsPtr);
      assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((limitsPtr) >> 2), "loading")] === 0);
      var requiredLimits = {};
      function setLimitU32IfDefined(name, limitOffset, ignoreIfZero = false) {
        var ptr = limitsPtr + limitOffset;
        var value = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")];
        if (value != 4294967295 && (!ignoreIfZero || value != 0)) {
          requiredLimits[name] = value;
        }
      }
      function setLimitU64IfDefined(name, limitOffset) {
        var ptr = limitsPtr + limitOffset;
        // Handle WGPU_LIMIT_U64_UNDEFINED.
        var limitPart1 = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")];
        var limitPart2 = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr) + (4)) >> 2), "loading")];
        if (limitPart1 != 4294967295 || limitPart2 != 4294967295) {
          requiredLimits[name] = (HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((ptr + 4)) >> 2), "loading")] * 4294967296 + HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")]);
        }
      }
      setLimitU32IfDefined("maxTextureDimension1D", 4);
      setLimitU32IfDefined("maxTextureDimension2D", 8);
      setLimitU32IfDefined("maxTextureDimension3D", 12);
      setLimitU32IfDefined("maxTextureArrayLayers", 16);
      setLimitU32IfDefined("maxBindGroups", 20);
      setLimitU32IfDefined("maxBindGroupsPlusVertexBuffers", 24);
      setLimitU32IfDefined("maxDynamicUniformBuffersPerPipelineLayout", 32);
      setLimitU32IfDefined("maxDynamicStorageBuffersPerPipelineLayout", 36);
      setLimitU32IfDefined("maxSampledTexturesPerShaderStage", 40);
      setLimitU32IfDefined("maxSamplersPerShaderStage", 44);
      setLimitU32IfDefined("maxStorageBuffersPerShaderStage", 48);
      setLimitU32IfDefined("maxStorageTexturesPerShaderStage", 52);
      setLimitU32IfDefined("maxUniformBuffersPerShaderStage", 56);
      setLimitU32IfDefined("minUniformBufferOffsetAlignment", 80);
      setLimitU32IfDefined("minStorageBufferOffsetAlignment", 84);
      setLimitU64IfDefined("maxUniformBufferBindingSize", 64);
      setLimitU64IfDefined("maxStorageBufferBindingSize", 72);
      setLimitU32IfDefined("maxVertexBuffers", 88);
      setLimitU64IfDefined("maxBufferSize", 96);
      setLimitU32IfDefined("maxVertexAttributes", 104);
      setLimitU32IfDefined("maxVertexBufferArrayStride", 108);
      setLimitU32IfDefined("maxInterStageShaderVariables", 112);
      setLimitU32IfDefined("maxColorAttachments", 116);
      setLimitU32IfDefined("maxColorAttachmentBytesPerSample", 120);
      setLimitU32IfDefined("maxComputeWorkgroupStorageSize", 124);
      setLimitU32IfDefined("maxComputeInvocationsPerWorkgroup", 128);
      setLimitU32IfDefined("maxComputeWorkgroupSizeX", 132);
      setLimitU32IfDefined("maxComputeWorkgroupSizeY", 136);
      setLimitU32IfDefined("maxComputeWorkgroupSizeZ", 140);
      setLimitU32IfDefined("maxComputeWorkgroupsPerDimension", 144);
      // Non-standard. If this is 0, avoid passing it through so it won't cause an error.
      setLimitU32IfDefined("maxImmediateSize", 148, true);
      desc["requiredLimits"] = requiredLimits;
    }
    var defaultQueuePtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (24)) >> 2), "loading")];
    if (defaultQueuePtr) {
      var defaultQueueDesc = {
        "label": WebGPU.makeStringFromOptionalStringView(defaultQueuePtr + 4)
      };
      desc["defaultQueue"] = defaultQueueDesc;
    }
    desc["label"] = WebGPU.makeStringFromOptionalStringView(descriptor + 4);
  }
  // requestDevice
  WebGPU.Internals.futureInsert(futureId, adapter.requestDevice(desc).then(device => {
    // requestDevice fulfilled
    callUserCallback(() => {
      WebGPU.Internals.jsObjectInsert(queuePtr, device.queue);
      WebGPU.Internals.jsObjectInsert(devicePtr, device);
      // Set up device lost promise resolution.
      assert(deviceLostFutureId);
      // Don't keepalive here, because this isn't guaranteed to ever happen.
      WebGPU.Internals.futureInsert(deviceLostFutureId, device.lost.then(info => {
        // If the runtime has exited, avoid calling callUserCallback as it
        // will print an error (e.g. if the device got freed during shutdown).
        callUserCallback(() => {
          // Unset the uncaptured error handler.
          device.onuncapturederror = ev => {};
          var sp = stackSave();
          var messagePtr = stringToUTF8OnStack(info.message);
          _emwgpuOnDeviceLostCompleted(deviceLostFutureId, emwgpuStringToInt_DeviceLostReason[info.reason], messagePtr);
          stackRestore(sp);
        });
      }));
      // Set up uncaptured error handlers.
      assert(typeof GPUValidationError != "undefined");
      assert(typeof GPUOutOfMemoryError != "undefined");
      assert(typeof GPUInternalError != "undefined");
      device.onuncapturederror = ev => {
        var type = 5;
        if (ev.error instanceof GPUValidationError) type = 2; else if (ev.error instanceof GPUOutOfMemoryError) type = 3; else if (ev.error instanceof GPUInternalError) type = 4;
        var sp = stackSave();
        var messagePtr = stringToUTF8OnStack(ev.error.message);
        _emwgpuOnUncapturedError(devicePtr, type, messagePtr);
        stackRestore(sp);
      };
      _emwgpuOnRequestDeviceCompleted(futureId, 1, devicePtr, 0);
    });
  }, ex => {
    // requestDevice rejected
    callUserCallback(() => {
      var sp = stackSave();
      var messagePtr = stringToUTF8OnStack(ex.message);
      _emwgpuOnRequestDeviceCompleted(futureId, 3, devicePtr, messagePtr);
      if (deviceLostFutureId) {
        _emwgpuOnDeviceLostCompleted(deviceLostFutureId, 4, messagePtr);
      }
      stackRestore(sp);
    });
  }));
}

var _emwgpuDelete = ptr => {
  delete WebGPU.Internals.jsObjects[ptr];
};

var _emwgpuDeviceCreateBuffer = (devicePtr, descriptor, bufferPtr) => {
  assert(descriptor);
  assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")] === 0);
  var mappedAtCreation = !!(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (32)) >> 2), "loading")]);
  var desc = {
    "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4),
    "usage": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (16)) >> 2), "loading")],
    "size": (HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((((descriptor + 4)) + (24)) >> 2), "loading")] * 4294967296 + HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (24)) >> 2), "loading")]),
    "mappedAtCreation": mappedAtCreation
  };
  var device = WebGPU.getJsObject(devicePtr);
  var buffer;
  try {
    buffer = device.createBuffer(desc);
  } catch (ex) {
    // The only exception should be RangeError if mapping at creation ran out of memory.
    assert(ex instanceof RangeError);
    assert(mappedAtCreation);
    err("createBuffer threw:", ex);
    return false;
  }
  WebGPU.Internals.jsObjectInsert(bufferPtr, buffer);
  if (mappedAtCreation) {
    WebGPU.Internals.bufferOnUnmaps[bufferPtr] = [];
  }
  return true;
};

var _emwgpuDeviceCreateShaderModule = (devicePtr, descriptor, shaderModulePtr) => {
  assert(descriptor);
  var nextInChainPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")];
  assert(nextInChainPtr !== 0);
  var sType = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((nextInChainPtr) + (4)) >> 2), "loading")];
  var desc = {
    "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4),
    "code": ""
  };
  switch (sType) {
   case 2:
    {
      desc["code"] = WebGPU.makeStringFromStringView(nextInChainPtr + 8);
      break;
    }

   default:
    abort("unrecognized ShaderModule sType");
  }
  var device = WebGPU.getJsObject(devicePtr);
  WebGPU.Internals.jsObjectInsert(shaderModulePtr, device.createShaderModule(desc));
};

var _emwgpuDeviceDestroy = devicePtr => {
  const device = WebGPU.getJsObject(devicePtr);
  // Remove the onuncapturederror handler which holds a pointer to the WGPUDevice.
  device.onuncapturederror = null;
  device.destroy();
};

var emwgpuStringToInt_PreferredFormat = {
  "rgba8unorm": 22,
  "bgra8unorm": 27
};

var _emwgpuGetPreferredFormat = () => {
  var format = navigator.gpu.getPreferredCanvasFormat();
  return emwgpuStringToInt_PreferredFormat[format];
};

function _emwgpuInstanceRequestAdapter(instancePtr, futureId, options, adapterPtr) {
  futureId = bigintToI53Checked(futureId);
  var opts;
  if (options) {
    assert(options);
    var featureLevel = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((options) + (4)) >> 2), "loading")];
    opts = {
      "featureLevel": WebGPU.FeatureLevel[featureLevel],
      "powerPreference": WebGPU.PowerPreference[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((options) + (8)) >> 2), "loading")]],
      "forceFallbackAdapter": !!(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((options) + (12)) >> 2), "loading")])
    };
    var nextInChainPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((options) >> 2), "loading")];
    if (nextInChainPtr !== 0) {
      var sType = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((nextInChainPtr) + (4)) >> 2), "loading")];
      assert(sType === 11);
      assert(0 === HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((nextInChainPtr) >> 2), "loading")]);
      var webxrOptions = nextInChainPtr;
      assert(webxrOptions);
      assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((webxrOptions) >> 2), "loading")] === 0);
      opts.xrCompatible = !!(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((webxrOptions) + (8)) >> 2), "loading")]);
    }
  }
  if (!("gpu" in navigator)) {
    var sp = stackSave();
    var messagePtr = stringToUTF8OnStack("WebGPU not available on this browser (navigator.gpu is not available)");
    _emwgpuOnRequestAdapterCompleted(futureId, 3, adapterPtr, messagePtr);
    stackRestore(sp);
    return;
  }
  // requestAdapter
  WebGPU.Internals.futureInsert(futureId, navigator.gpu.requestAdapter(opts).then(adapter => {
    // requestAdapter fulfilled
    callUserCallback(() => {
      if (adapter) {
        WebGPU.Internals.jsObjectInsert(adapterPtr, adapter);
        _emwgpuOnRequestAdapterCompleted(futureId, 1, adapterPtr, 0);
      } else {
        var sp = stackSave();
        var messagePtr = stringToUTF8OnStack("WebGPU not available on this browser (requestAdapter returned null)");
        _emwgpuOnRequestAdapterCompleted(futureId, 3, adapterPtr, messagePtr);
        stackRestore(sp);
      }
    });
  }, ex => {
    // requestAdapter rejected
    callUserCallback(() => {
      var sp = stackSave();
      var messagePtr = stringToUTF8OnStack(ex.message);
      _emwgpuOnRequestAdapterCompleted(futureId, 4, adapterPtr, messagePtr);
      stackRestore(sp);
    });
  }));
}

var SYSCALLS = {
  varargs: undefined,
  getStr(ptr) {
    var ret = UTF8ToString(ptr);
    return ret;
  }
};

var _fd_close = fd => {
  abort("fd_close called without SYSCALLS_REQUIRE_FILESYSTEM");
};

function _fd_seek(fd, offset, whence, newOffset) {
  offset = bigintToI53Checked(offset);
  return 70;
}

var printCharBuffers = [ null, [], [] ];

var printChar = (stream, curr) => {
  var buffer = printCharBuffers[stream];
  assert(buffer);
  if (curr === 0 || curr === 10) {
    (stream === 1 ? out : err)(UTF8ArrayToString(buffer));
    buffer.length = 0;
  } else {
    buffer.push(curr);
  }
};

var flush_NO_FILESYSTEM = () => {
  // flush anything remaining in the buffers during shutdown
  _fflush(0);
  if (printCharBuffers[1].length) printChar(1, 10);
  if (printCharBuffers[2].length) printChar(2, 10);
};

var _fd_write = (fd, iov, iovcnt, pnum) => {
  // hack to support printf in SYSCALLS_REQUIRE_FILESYSTEM=0
  var num = 0;
  for (var i = 0; i < iovcnt; i++) {
    var ptr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((iov) >> 2), "loading")];
    var len = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((iov) + (4)) >> 2), "loading")];
    iov += 8;
    for (var j = 0; j < len; j++) {
      printChar(fd, HEAPU8[SAFE_HEAP_INDEX(HEAPU8, ptr + j, "loading")]);
    }
    num += len;
  }
  HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((pnum) >> 2), "storing")] = num;
  checkInt32(num);
  return 0;
};

var _wgpuCommandEncoderBeginRenderPass = (encoderPtr, descriptor) => {
  assert(descriptor);
  function makeColorAttachment(caPtr) {
    var viewPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((caPtr) + (4)) >> 2), "loading")];
    if (viewPtr === 0) {
      // view could be undefined.
      return undefined;
    }
    var depthSlice = HEAP32[SAFE_HEAP_INDEX(HEAP32, (((caPtr) + (8)) >> 2), "loading")];
    if (depthSlice == -1) depthSlice = undefined;
    var loadOpInt = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((caPtr) + (16)) >> 2), "loading")];
    assert(loadOpInt !== 0);
    var storeOpInt = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((caPtr) + (20)) >> 2), "loading")];
    assert(storeOpInt !== 0);
    var clearValue = WebGPU.makeColor(caPtr + 24);
    return {
      "view": WebGPU.getJsObject(viewPtr),
      "depthSlice": depthSlice,
      "resolveTarget": WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((caPtr) + (12)) >> 2), "loading")]),
      "clearValue": clearValue,
      "loadOp": WebGPU.LoadOp[loadOpInt],
      "storeOp": WebGPU.StoreOp[storeOpInt]
    };
  }
  function makeColorAttachments(count, caPtr) {
    var attachments = [];
    for (var i = 0; i < count; ++i) {
      attachments.push(makeColorAttachment(caPtr + 56 * i));
    }
    return attachments;
  }
  function makeDepthStencilAttachment(dsaPtr) {
    if (dsaPtr === 0) return undefined;
    return {
      "view": WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dsaPtr) + (4)) >> 2), "loading")]),
      "depthClearValue": HEAPF32[SAFE_HEAP_INDEX(HEAPF32, (((dsaPtr) + (16)) >> 2), "loading")],
      "depthLoadOp": WebGPU.LoadOp[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dsaPtr) + (8)) >> 2), "loading")]],
      "depthStoreOp": WebGPU.StoreOp[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dsaPtr) + (12)) >> 2), "loading")]],
      "depthReadOnly": !!(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dsaPtr) + (20)) >> 2), "loading")]),
      "stencilClearValue": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dsaPtr) + (32)) >> 2), "loading")],
      "stencilLoadOp": WebGPU.LoadOp[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dsaPtr) + (24)) >> 2), "loading")]],
      "stencilStoreOp": WebGPU.StoreOp[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dsaPtr) + (28)) >> 2), "loading")]],
      "stencilReadOnly": !!(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((dsaPtr) + (36)) >> 2), "loading")])
    };
  }
  function makeRenderPassDescriptor(descriptor) {
    assert(descriptor);
    var nextInChainPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")];
    var maxDrawCount = undefined;
    if (nextInChainPtr !== 0) {
      var sType = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((nextInChainPtr) + (4)) >> 2), "loading")];
      assert(sType === 3);
      assert(0 === HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((nextInChainPtr) >> 2), "loading")]);
      var renderPassMaxDrawCount = nextInChainPtr;
      assert(renderPassMaxDrawCount);
      assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((renderPassMaxDrawCount) >> 2), "loading")] === 0);
      maxDrawCount = (HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((((renderPassMaxDrawCount + 4)) + (8)) >> 2), "loading")] * 4294967296 + HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((renderPassMaxDrawCount) + (8)) >> 2), "loading")]);
    }
    var desc = {
      "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4),
      "colorAttachments": makeColorAttachments(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (12)) >> 2), "loading")], HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (16)) >> 2), "loading")]),
      "depthStencilAttachment": makeDepthStencilAttachment(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (20)) >> 2), "loading")]),
      "occlusionQuerySet": WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (24)) >> 2), "loading")]),
      "timestampWrites": WebGPU.makePassTimestampWrites(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (28)) >> 2), "loading")]),
      "maxDrawCount": maxDrawCount
    };
    return desc;
  }
  var desc = makeRenderPassDescriptor(descriptor);
  var commandEncoder = WebGPU.getJsObject(encoderPtr);
  var ptr = _emwgpuCreateRenderPassEncoder(0);
  WebGPU.Internals.jsObjectInsert(ptr, commandEncoder.beginRenderPass(desc));
  return ptr;
};

var _wgpuCommandEncoderFinish = (encoderPtr, descriptor) => {
  // TODO: Use the descriptor.
  var commandEncoder = WebGPU.getJsObject(encoderPtr);
  var ptr = _emwgpuCreateCommandBuffer(0);
  WebGPU.Internals.jsObjectInsert(ptr, commandEncoder.finish());
  return ptr;
};

var readI53FromI64 = ptr => HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")] + HEAP32[SAFE_HEAP_INDEX(HEAP32, (((ptr) + (4)) >> 2), "loading")] * 4294967296;

var _wgpuDeviceCreateBindGroup = (devicePtr, descriptor) => {
  assert(descriptor);
  assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")] === 0);
  function makeEntry(entryPtr) {
    assert(entryPtr);
    var bufferPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (8)) >> 2), "loading")];
    var samplerPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (32)) >> 2), "loading")];
    var textureViewPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (36)) >> 2), "loading")];
    assert((bufferPtr !== 0) + (samplerPtr !== 0) + (textureViewPtr !== 0) === 1);
    var binding = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (4)) >> 2), "loading")];
    if (bufferPtr) {
      var size = readI53FromI64((entryPtr) + (24));
      if (size == -1) size = undefined;
      return {
        "binding": binding,
        "resource": {
          "buffer": WebGPU.getJsObject(bufferPtr),
          "offset": (HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((((entryPtr + 4)) + (16)) >> 2), "loading")] * 4294967296 + HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (16)) >> 2), "loading")]),
          "size": size
        }
      };
    } else if (samplerPtr) {
      return {
        "binding": binding,
        "resource": WebGPU.getJsObject(samplerPtr)
      };
    } else {
      return {
        "binding": binding,
        "resource": WebGPU.getJsObject(textureViewPtr)
      };
    }
  }
  function makeEntries(count, entriesPtrs) {
    var entries = [];
    for (var i = 0; i < count; ++i) {
      entries.push(makeEntry(entriesPtrs + 40 * i));
    }
    return entries;
  }
  var desc = {
    "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4),
    "layout": WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (12)) >> 2), "loading")]),
    "entries": makeEntries(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (16)) >> 2), "loading")], HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (20)) >> 2), "loading")])
  };
  var device = WebGPU.getJsObject(devicePtr);
  var ptr = _emwgpuCreateBindGroup(0);
  WebGPU.Internals.jsObjectInsert(ptr, device.createBindGroup(desc));
  return ptr;
};

var _wgpuDeviceCreateBindGroupLayout = (devicePtr, descriptor) => {
  assert(descriptor);
  assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")] === 0);
  function makeBufferEntry(entryPtr) {
    assert(entryPtr);
    var typeInt = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (4)) >> 2), "loading")];
    if (!typeInt) return undefined;
    return {
      "type": WebGPU.BufferBindingType[typeInt],
      "hasDynamicOffset": !!(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (8)) >> 2), "loading")]),
      "minBindingSize": (HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((((entryPtr + 4)) + (16)) >> 2), "loading")] * 4294967296 + HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (16)) >> 2), "loading")])
    };
  }
  function makeSamplerEntry(entryPtr) {
    assert(entryPtr);
    var typeInt = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (4)) >> 2), "loading")];
    if (!typeInt) return undefined;
    return {
      "type": WebGPU.SamplerBindingType[typeInt]
    };
  }
  function makeTextureEntry(entryPtr) {
    assert(entryPtr);
    var sampleTypeInt = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (4)) >> 2), "loading")];
    if (!sampleTypeInt) return undefined;
    return {
      "sampleType": WebGPU.TextureSampleType[sampleTypeInt],
      "viewDimension": WebGPU.TextureViewDimension[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (8)) >> 2), "loading")]],
      "multisampled": !!(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (12)) >> 2), "loading")])
    };
  }
  function makeStorageTextureEntry(entryPtr) {
    assert(entryPtr);
    var accessInt = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (4)) >> 2), "loading")];
    if (!accessInt) return undefined;
    return {
      "access": WebGPU.StorageTextureAccess[accessInt],
      "format": WebGPU.TextureFormat[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (8)) >> 2), "loading")]],
      "viewDimension": WebGPU.TextureViewDimension[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (12)) >> 2), "loading")]]
    };
  }
  function makeEntry(entryPtr) {
    assert(entryPtr);
    // bindingArraySize is not specced and thus not implemented yet. We don't pass it through
    // because if we did, then existing apps using this version of the bindings could break when
    // browsers start accepting bindingArraySize.
    var bindingArraySize = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (16)) >> 2), "loading")];
    assert(bindingArraySize == 0 || bindingArraySize == 1);
    return {
      "binding": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (4)) >> 2), "loading")],
      "visibility": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((entryPtr) + (8)) >> 2), "loading")],
      "buffer": makeBufferEntry(entryPtr + 24),
      "sampler": makeSamplerEntry(entryPtr + 48),
      "texture": makeTextureEntry(entryPtr + 56),
      "storageTexture": makeStorageTextureEntry(entryPtr + 72)
    };
  }
  function makeEntries(count, entriesPtrs) {
    var entries = [];
    for (var i = 0; i < count; ++i) {
      entries.push(makeEntry(entriesPtrs + 88 * i));
    }
    return entries;
  }
  var desc = {
    "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4),
    "entries": makeEntries(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (12)) >> 2), "loading")], HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (16)) >> 2), "loading")])
  };
  var device = WebGPU.getJsObject(devicePtr);
  var ptr = _emwgpuCreateBindGroupLayout(0);
  WebGPU.Internals.jsObjectInsert(ptr, device.createBindGroupLayout(desc));
  return ptr;
};

var _wgpuDeviceCreateCommandEncoder = (devicePtr, descriptor) => {
  var desc;
  if (descriptor) {
    assert(descriptor);
    assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")] === 0);
    desc = {
      "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4)
    };
  }
  var device = WebGPU.getJsObject(devicePtr);
  var ptr = _emwgpuCreateCommandEncoder(0);
  WebGPU.Internals.jsObjectInsert(ptr, device.createCommandEncoder(desc));
  return ptr;
};

var _wgpuDeviceCreatePipelineLayout = (devicePtr, descriptor) => {
  assert(descriptor);
  assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")] === 0);
  var bglCount = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (12)) >> 2), "loading")];
  var bglPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (16)) >> 2), "loading")];
  var bgls = [];
  for (var i = 0; i < bglCount; ++i) {
    bgls.push(WebGPU.getJsObject(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((bglPtr) + (4 * i)) >> 2), "loading")]));
  }
  var desc = {
    "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4),
    "bindGroupLayouts": bgls
  };
  var device = WebGPU.getJsObject(devicePtr);
  var ptr = _emwgpuCreatePipelineLayout(0);
  WebGPU.Internals.jsObjectInsert(ptr, device.createPipelineLayout(desc));
  return ptr;
};

var _wgpuDeviceCreateRenderPipeline = (devicePtr, descriptor) => {
  var desc = WebGPU.makeRenderPipelineDesc(descriptor);
  var device = WebGPU.getJsObject(devicePtr);
  var ptr = _emwgpuCreateRenderPipeline(0);
  WebGPU.Internals.jsObjectInsert(ptr, device.createRenderPipeline(desc));
  return ptr;
};

var _wgpuDeviceCreateTexture = (devicePtr, descriptor) => {
  assert(descriptor);
  assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")] === 0);
  var desc = {
    "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4),
    "size": WebGPU.makeExtent3D(descriptor + 28),
    "mipLevelCount": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (44)) >> 2), "loading")],
    "sampleCount": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (48)) >> 2), "loading")],
    "dimension": WebGPU.TextureDimension[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (24)) >> 2), "loading")]],
    "format": WebGPU.TextureFormat[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (40)) >> 2), "loading")]],
    "usage": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (16)) >> 2), "loading")]
  };
  var viewFormatCount = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (52)) >> 2), "loading")];
  if (viewFormatCount) {
    var viewFormatsPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (56)) >> 2), "loading")];
    // viewFormatsPtr pointer to an array of TextureFormat which is an enum of size uint32_t
    desc["viewFormats"] = Array.from(HEAP32.subarray((((viewFormatsPtr) >> 2)), ((viewFormatsPtr + viewFormatCount * 4) >> 2)), format => WebGPU.TextureFormat[format]);
  }
  var device = WebGPU.getJsObject(devicePtr);
  var ptr = _emwgpuCreateTexture(0);
  WebGPU.Internals.jsObjectInsert(ptr, device.createTexture(desc));
  return ptr;
};

var maybeCStringToJsString = cString => cString > 2 ? UTF8ToString(cString) : cString;

/** @type {Object} */ var specialHTMLTargets = [ 0, globalThis.document ?? 0, globalThis.window ?? 0 ];

var findEventTarget = target => {
  target = maybeCStringToJsString(target);
  var domElement = specialHTMLTargets[target] || globalThis.document?.querySelector(target);
  return domElement;
};

var findCanvasEventTarget = findEventTarget;

var _wgpuInstanceCreateSurface = (instancePtr, descriptor) => {
  assert(descriptor);
  var nextInChainPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")];
  assert(nextInChainPtr !== 0);
  assert(262144 === HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((nextInChainPtr) + (4)) >> 2), "loading")]);
  var sourceCanvasHTMLSelector = nextInChainPtr;
  assert(sourceCanvasHTMLSelector);
  assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((sourceCanvasHTMLSelector) >> 2), "loading")] === 0);
  var selectorPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((sourceCanvasHTMLSelector) + (8)) >> 2), "loading")];
  assert(selectorPtr);
  var canvas = findCanvasEventTarget(selectorPtr);
  var context = canvas.getContext("webgpu");
  assert(context);
  if (!context) return 0;
  context.surfaceLabelWebGPU = WebGPU.makeStringFromOptionalStringView(descriptor + 4);
  var ptr = _emwgpuCreateSurface(0);
  WebGPU.Internals.jsObjectInsert(ptr, context);
  return ptr;
};

var _wgpuQueueSubmit = (queuePtr, commandCount, commands) => {
  assert(commands % 4 === 0);
  var queue = WebGPU.getJsObject(queuePtr);
  var cmds = Array.from(HEAP32.subarray((((commands) >> 2)), ((commands + commandCount * 4) >> 2)), id => WebGPU.getJsObject(id));
  queue.submit(cmds);
};

function _wgpuQueueWriteBuffer(queuePtr, bufferPtr, bufferOffset, data, size) {
  bufferOffset = bigintToI53Checked(bufferOffset);
  var queue = WebGPU.getJsObject(queuePtr);
  var buffer = WebGPU.getJsObject(bufferPtr);
  // There is a size limitation for ArrayBufferView. Work around by passing in a subarray
  // instead of the whole heap. crbug.com/1201109
  var subarray = HEAPU8.subarray(data, data + size);
  queue.writeBuffer(buffer, bufferOffset, subarray, 0, size);
}

var _wgpuRenderPassEncoderDrawIndexed = (passPtr, indexCount, instanceCount, firstIndex, baseVertex, firstInstance) => {
  assert(indexCount >= 0);
  assert(instanceCount >= 0);
  firstIndex >>>= 0;
  firstInstance >>>= 0;
  var pass = WebGPU.getJsObject(passPtr);
  pass.drawIndexed(indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
};

var _wgpuRenderPassEncoderEnd = encoderPtr => {
  var encoder = WebGPU.getJsObject(encoderPtr);
  encoder.end();
};

var _wgpuRenderPassEncoderSetBindGroup = (passPtr, groupIndex, groupPtr, dynamicOffsetCount, dynamicOffsetsPtr) => {
  assert(groupIndex >= 0);
  var pass = WebGPU.getJsObject(passPtr);
  var group = WebGPU.getJsObject(groupPtr);
  if (dynamicOffsetCount == 0) {
    pass.setBindGroup(groupIndex, group);
  } else {
    pass.setBindGroup(groupIndex, group, HEAPU32, ((dynamicOffsetsPtr) >> 2), dynamicOffsetCount);
  }
};

function _wgpuRenderPassEncoderSetIndexBuffer(passPtr, bufferPtr, format, offset, size) {
  offset = bigintToI53Checked(offset);
  size = bigintToI53Checked(size);
  var pass = WebGPU.getJsObject(passPtr);
  var buffer = WebGPU.getJsObject(bufferPtr);
  if (size == -1) size = undefined;
  pass.setIndexBuffer(buffer, WebGPU.IndexFormat[format], offset, size);
}

var _wgpuRenderPassEncoderSetPipeline = (passPtr, pipelinePtr) => {
  var pass = WebGPU.getJsObject(passPtr);
  var pipeline = WebGPU.getJsObject(pipelinePtr);
  pass.setPipeline(pipeline);
};

function _wgpuRenderPassEncoderSetVertexBuffer(passPtr, slot, bufferPtr, offset, size) {
  offset = bigintToI53Checked(offset);
  size = bigintToI53Checked(size);
  assert(slot >= 0);
  var pass = WebGPU.getJsObject(passPtr);
  var buffer = WebGPU.getJsObject(bufferPtr);
  if (size == -1) size = undefined;
  pass.setVertexBuffer(slot, buffer, offset, size);
}

var _wgpuSurfaceConfigure = (surfacePtr, config) => {
  assert(config);
  var devicePtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((config) + (4)) >> 2), "loading")];
  var context = WebGPU.getJsObject(surfacePtr);
  var presentMode = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((config) + (44)) >> 2), "loading")];
  assert(presentMode === 1 || presentMode === 0);
  var canvasSize = [ HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((config) + (24)) >> 2), "loading")], HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((config) + (28)) >> 2), "loading")] ];
  if (canvasSize[0] !== 0) {
    context["canvas"]["width"] = canvasSize[0];
  }
  if (canvasSize[1] !== 0) {
    context["canvas"]["height"] = canvasSize[1];
  }
  var configuration = {
    "device": WebGPU.getJsObject(devicePtr),
    "format": WebGPU.TextureFormat[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((config) + (8)) >> 2), "loading")]],
    "usage": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((config) + (16)) >> 2), "loading")],
    "alphaMode": WebGPU.CompositeAlphaMode[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((config) + (40)) >> 2), "loading")]]
  };
  var viewFormatCount = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((config) + (32)) >> 2), "loading")];
  if (viewFormatCount) {
    var viewFormatsPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((config) + (36)) >> 2), "loading")];
    // viewFormatsPtr pointer to an array of TextureFormat which is an enum of size uint32_t
    configuration["viewFormats"] = Array.from(HEAP32.subarray((((viewFormatsPtr) >> 2)), ((viewFormatsPtr + viewFormatCount * 4) >> 2)), format => WebGPU.TextureFormat[format]);
  }
  {
    var nextInChainPtr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((config) >> 2), "loading")];
    if (nextInChainPtr !== 0) {
      var sType = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((nextInChainPtr) + (4)) >> 2), "loading")];
      assert(sType === 10);
      assert(0 === HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((nextInChainPtr) >> 2), "loading")]);
      var surfaceColorManagement = nextInChainPtr;
      assert(surfaceColorManagement);
      assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((surfaceColorManagement) >> 2), "loading")] === 0);
      configuration.colorSpace = WebGPU.PredefinedColorSpace[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((surfaceColorManagement) + (8)) >> 2), "loading")]];
      configuration.toneMapping = {
        mode: WebGPU.ToneMappingMode[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((surfaceColorManagement) + (12)) >> 2), "loading")]]
      };
    }
  }
  context.configure(configuration);
};

var _wgpuSurfaceGetCurrentTexture = (surfacePtr, surfaceTexturePtr) => {
  assert(surfaceTexturePtr);
  var context = WebGPU.getJsObject(surfacePtr);
  try {
    var texturePtr = _emwgpuCreateTexture(0);
    WebGPU.Internals.jsObjectInsert(texturePtr, context.getCurrentTexture());
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((surfaceTexturePtr) + (4)) >> 2), "storing")] = texturePtr;
    HEAP32[SAFE_HEAP_INDEX(HEAP32, (((surfaceTexturePtr) + (8)) >> 2), "storing")] = 1;
    checkInt32(1);
  } catch (ex) {
    err(`wgpuSurfaceGetCurrentTexture() failed: ${ex}`);
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((surfaceTexturePtr) + (4)) >> 2), "storing")] = 0;
    HEAP32[SAFE_HEAP_INDEX(HEAP32, (((surfaceTexturePtr) + (8)) >> 2), "storing")] = 6;
    checkInt32(6);
  }
};

var _wgpuTextureCreateView = (texturePtr, descriptor) => {
  var desc;
  if (descriptor) {
    assert(descriptor);
    assert(HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((descriptor) >> 2), "loading")] === 0);
    var mipLevelCount = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (24)) >> 2), "loading")];
    var arrayLayerCount = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (32)) >> 2), "loading")];
    desc = {
      "label": WebGPU.makeStringFromOptionalStringView(descriptor + 4),
      "format": WebGPU.TextureFormat[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (12)) >> 2), "loading")]],
      "dimension": WebGPU.TextureViewDimension[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (16)) >> 2), "loading")]],
      "baseMipLevel": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (20)) >> 2), "loading")],
      "mipLevelCount": mipLevelCount === 4294967295 ? undefined : mipLevelCount,
      "baseArrayLayer": HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (28)) >> 2), "loading")],
      "arrayLayerCount": arrayLayerCount === 4294967295 ? undefined : arrayLayerCount,
      "aspect": WebGPU.TextureAspect[HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((descriptor) + (36)) >> 2), "loading")]]
    };
  }
  var texture = WebGPU.getJsObject(texturePtr);
  var ptr = _emwgpuCreateTextureView(0);
  WebGPU.Internals.jsObjectInsert(ptr, texture.createView(desc));
  return ptr;
};

Module["requestAnimationFrame"] = MainLoop.requestAnimationFrame;

Module["pauseMainLoop"] = MainLoop.pause;

Module["resumeMainLoop"] = MainLoop.resume;

MainLoop.init();

// End JS library code
// include: postlibrary.js
// This file is included after the automatically-generated JS library code
// but before the wasm module is created.
{
  // Begin ATMODULES hooks
  if (Module["noExitRuntime"]) noExitRuntime = Module["noExitRuntime"];
  if (Module["print"]) out = Module["print"];
  if (Module["printErr"]) err = Module["printErr"];
  if (Module["wasmBinary"]) wasmBinary = Module["wasmBinary"];
  Module["FS_createDataFile"] = FS.createDataFile;
  Module["FS_createPreloadedFile"] = FS.createPreloadedFile;
  // End ATMODULES hooks
  checkIncomingModuleAPI();
  if (Module["arguments"]) arguments_ = Module["arguments"];
  if (Module["thisProgram"]) thisProgram = Module["thisProgram"];
  // Assertions on removed incoming Module JS APIs.
  assert(typeof Module["memoryInitializerPrefixURL"] == "undefined", "Module.memoryInitializerPrefixURL option was removed, use Module.locateFile instead");
  assert(typeof Module["pthreadMainPrefixURL"] == "undefined", "Module.pthreadMainPrefixURL option was removed, use Module.locateFile instead");
  assert(typeof Module["cdInitializerPrefixURL"] == "undefined", "Module.cdInitializerPrefixURL option was removed, use Module.locateFile instead");
  assert(typeof Module["filePackagePrefixURL"] == "undefined", "Module.filePackagePrefixURL option was removed, use Module.locateFile instead");
  assert(typeof Module["read"] == "undefined", "Module.read option was removed");
  assert(typeof Module["readAsync"] == "undefined", "Module.readAsync option was removed (modify readAsync in JS)");
  assert(typeof Module["readBinary"] == "undefined", "Module.readBinary option was removed (modify readBinary in JS)");
  assert(typeof Module["setWindowTitle"] == "undefined", "Module.setWindowTitle option was removed (modify emscripten_set_window_title in JS)");
  assert(typeof Module["TOTAL_MEMORY"] == "undefined", "Module.TOTAL_MEMORY has been renamed Module.INITIAL_MEMORY");
  assert(typeof Module["ENVIRONMENT"] == "undefined", "Module.ENVIRONMENT has been deprecated. To force the environment, use the ENVIRONMENT compile-time option (for example, -sENVIRONMENT=web or -sENVIRONMENT=node)");
  assert(typeof Module["STACK_SIZE"] == "undefined", "STACK_SIZE can no longer be set at runtime.  Use -sSTACK_SIZE at link time");
  // If memory is defined in wasm, the user can't provide it, or set INITIAL_MEMORY
  assert(typeof Module["wasmMemory"] == "undefined", "Use of `wasmMemory` detected.  Use -sIMPORTED_MEMORY to define wasmMemory externally");
  assert(typeof Module["INITIAL_MEMORY"] == "undefined", "Detected runtime INITIAL_MEMORY setting.  Use -sIMPORTED_MEMORY to define wasmMemory dynamically");
  if (Module["preInit"]) {
    if (typeof Module["preInit"] == "function") Module["preInit"] = [ Module["preInit"] ];
    while (Module["preInit"].length > 0) {
      Module["preInit"].shift()();
    }
  }
  consumedModuleProp("preInit");
}

// Begin runtime exports
var missingLibrarySymbols = [ "writeI53ToI64", "writeI53ToI64Clamped", "writeI53ToI64Signaling", "writeI53ToU64Clamped", "writeI53ToU64Signaling", "readI53FromU64", "convertI32PairToI53", "convertI32PairToI53Checked", "convertU32PairToI53", "getTempRet0", "setTempRet0", "createNamedFunction", "zeroMemory", "withStackSave", "strError", "inetPton4", "inetNtop4", "inetPton6", "inetNtop6", "readSockaddr", "writeSockaddr", "readEmAsmArgs", "jstoi_q", "getExecutableName", "autoResumeAudioContext", "getDynCaller", "dynCall", "runtimeKeepalivePush", "runtimeKeepalivePop", "asyncLoad", "asmjsMangle", "mmapAlloc", "HandleAllocator", "getUniqueRunDependency", "addOnInit", "addOnPostCtor", "addOnPreMain", "addOnExit", "STACK_SIZE", "STACK_ALIGN", "POINTER_SIZE", "ASSERTIONS", "ccall", "cwrap", "convertJsFunctionToWasm", "getEmptyTableSlot", "updateTableMap", "getFunctionAddress", "addFunction", "removeFunction", "intArrayFromString", "intArrayToString", "AsciiToString", "stringToAscii", "UTF16ToString", "stringToUTF16", "lengthBytesUTF16", "UTF32ToString", "stringToUTF32", "lengthBytesUTF32", "writeArrayToMemory", "registerKeyEventCallback", "getBoundingClientRect", "fillMouseEventData", "registerMouseEventCallback", "registerWheelEventCallback", "registerUiEventCallback", "registerFocusEventCallback", "fillDeviceOrientationEventData", "registerDeviceOrientationEventCallback", "fillDeviceMotionEventData", "registerDeviceMotionEventCallback", "screenOrientation", "fillOrientationChangeEventData", "registerOrientationChangeEventCallback", "fillFullscreenChangeEventData", "registerFullscreenChangeEventCallback", "JSEvents_requestFullscreen", "JSEvents_resizeCanvasForFullscreen", "registerRestoreOldStyle", "hideEverythingExceptGivenElement", "restoreHiddenElements", "setLetterbox", "softFullscreenResizeWebGLRenderTarget", "doRequestFullscreen", "fillPointerlockChangeEventData", "registerPointerlockChangeEventCallback", "registerPointerlockErrorEventCallback", "requestPointerLock", "fillVisibilityChangeEventData", "registerVisibilityChangeEventCallback", "registerTouchEventCallback", "fillGamepadEventData", "registerGamepadEventCallback", "registerBeforeUnloadEventCallback", "fillBatteryEventData", "registerBatteryEventCallback", "setCanvasElementSize", "getCanvasElementSize", "jsStackTrace", "getCallstack", "convertPCtoSourceLocation", "getEnvStrings", "wasiRightsToMuslOFlags", "wasiOFlagsToMuslOFlags", "initRandomFill", "randomFill", "safeSetTimeout", "setImmediateWrapped", "safeRequestAnimationFrame", "clearImmediateWrapped", "registerPostMainLoop", "registerPreMainLoop", "getPromise", "makePromise", "idsToPromises", "makePromiseCallback", "findMatchingCatch", "incrementUncaughtExceptionCount", "decrementUncaughtExceptionCount", "Browser_asyncPrepareDataCounter", "isLeapYear", "ydayFromDate", "arraySum", "addDays", "getSocketFromFD", "getSocketAddress", "FS_createPreloadedFile", "FS_preloadFile", "FS_modeStringToFlags", "FS_getMode", "FS_fileDataToTypedArray", "FS_stdin_getChar", "FS_mkdirTree", "_setNetworkCallback", "heapObjectForWebGLType", "toTypedArrayIndex", "webgl_enable_ANGLE_instanced_arrays", "webgl_enable_OES_vertex_array_object", "webgl_enable_WEBGL_draw_buffers", "webgl_enable_WEBGL_multi_draw", "webgl_enable_EXT_polygon_offset_clamp", "webgl_enable_EXT_clip_control", "webgl_enable_WEBGL_polygon_mode", "emscriptenWebGLGet", "computeUnpackAlignedImageSize", "colorChannelsInGlTextureFormat", "emscriptenWebGLGetTexPixelData", "emscriptenWebGLGetUniform", "webglGetUniformLocation", "webglPrepareUniformLocationsBeforeFirstUse", "webglGetLeftBracePos", "emscriptenWebGLGetVertexAttrib", "__glGetActiveAttribOrUniform", "writeGLArray", "registerWebGlEventCallback", "runAndAbortIfError", "GLFW_Window", "emscriptenWebGLGetIndexed", "webgl_enable_WEBGL_draw_instanced_base_vertex_base_instance", "webgl_enable_WEBGL_multi_draw_instanced_base_vertex_base_instance", "ALLOC_NORMAL", "ALLOC_STACK", "allocate", "writeStringToMemory", "writeAsciiToMemory", "allocateUTF8", "allocateUTF8OnStack", "demangle", "stackTrace", "getNativeTypeSize" ];

missingLibrarySymbols.forEach(missingLibrarySymbol);

var unexportedSymbols = [ "run", "out", "err", "callMain", "abort", "wasmExports", "writeStackCookie", "checkStackCookie", "readI53FromI64", "INT53_MAX", "INT53_MIN", "bigintToI53Checked", "HEAP8", "HEAPU8", "HEAP16", "HEAPU16", "HEAP32", "HEAPU32", "HEAPF32", "HEAPF64", "HEAP64", "HEAPU64", "stackSave", "stackRestore", "stackAlloc", "ptrToString", "exitJS", "getHeapMax", "growMemory", "ENV", "setStackLimits", "ERRNO_CODES", "DNS", "Protocols", "Sockets", "timers", "warnOnce", "readEmAsmArgsArray", "handleException", "keepRuntimeAlive", "callUserCallback", "maybeExit", "alignMemory", "wasmTable", "wasmMemory", "noExitRuntime", "addRunDependency", "removeRunDependency", "addOnPreRun", "addOnPostRun", "freeTableIndexes", "functionsInTableMap", "setValue", "getValue", "PATH", "PATH_FS", "UTF8Decoder", "UTF8ArrayToString", "UTF8ToString", "stringToUTF8Array", "stringToUTF8", "lengthBytesUTF8", "UTF16Decoder", "stringToNewUTF8", "stringToUTF8OnStack", "JSEvents", "specialHTMLTargets", "maybeCStringToJsString", "findEventTarget", "findCanvasEventTarget", "currentFullscreenStrategy", "restoreOldWindowedStyle", "UNWIND_CACHE", "ExitStatus", "checkWasiClock", "flush_NO_FILESYSTEM", "emSetImmediate", "emClearImmediate_deps", "emClearImmediate", "promiseMap", "uncaughtExceptionCount", "exceptionCaught", "ExceptionInfo", "Browser", "requestFullscreen", "requestFullScreen", "setCanvasSize", "getUserMedia", "createContext", "getPreloadedImageData__data", "wget", "MONTH_DAYS_REGULAR", "MONTH_DAYS_LEAP", "MONTH_DAYS_REGULAR_CUMULATIVE", "MONTH_DAYS_LEAP_CUMULATIVE", "SYSCALLS", "preloadPlugins", "FS_stdin_getChar_buffer", "FS_unlink", "FS_createPath", "FS_createDevice", "FS_readFile", "FS", "FS_root", "FS_mounts", "FS_devices", "FS_streams", "FS_nextInode", "FS_nameTable", "FS_currentPath", "FS_initialized", "FS_ignorePermissions", "FS_filesystems", "FS_syncFSRequests", "FS_lookupPath", "FS_getPath", "FS_hashName", "FS_hashAddNode", "FS_hashRemoveNode", "FS_lookupNode", "FS_createNode", "FS_destroyNode", "FS_isRoot", "FS_isMountpoint", "FS_isFile", "FS_isDir", "FS_isLink", "FS_isChrdev", "FS_isBlkdev", "FS_isFIFO", "FS_isSocket", "FS_flagsToPermissionString", "FS_nodePermissions", "FS_mayLookup", "FS_mayCreate", "FS_mayDelete", "FS_mayOpen", "FS_checkOpExists", "FS_nextfd", "FS_getStreamChecked", "FS_getStream", "FS_createStream", "FS_closeStream", "FS_dupStream", "FS_doSetAttr", "FS_chrdev_stream_ops", "FS_major", "FS_minor", "FS_makedev", "FS_registerDevice", "FS_getDevice", "FS_getMounts", "FS_syncfs", "FS_mount", "FS_unmount", "FS_lookup", "FS_mknod", "FS_statfs", "FS_statfsStream", "FS_statfsNode", "FS_create", "FS_mkdir", "FS_mkdev", "FS_symlink", "FS_rename", "FS_rmdir", "FS_readdir", "FS_readlink", "FS_stat", "FS_fstat", "FS_lstat", "FS_doChmod", "FS_chmod", "FS_lchmod", "FS_fchmod", "FS_doChown", "FS_chown", "FS_lchown", "FS_fchown", "FS_doTruncate", "FS_truncate", "FS_ftruncate", "FS_utime", "FS_open", "FS_close", "FS_isClosed", "FS_llseek", "FS_read", "FS_write", "FS_mmap", "FS_msync", "FS_ioctl", "FS_writeFile", "FS_cwd", "FS_chdir", "FS_createDefaultDirectories", "FS_createDefaultDevices", "FS_createSpecialDirectories", "FS_createStandardStreams", "FS_staticInit", "FS_init", "FS_quit", "FS_findObject", "FS_analyzePath", "FS_createFile", "FS_createDataFile", "FS_forceLoadFile", "FS_createLazyFile", "MEMFS", "TTY", "PIPEFS", "SOCKFS", "tempFixedLengthArray", "miniTempWebGLFloatBuffers", "miniTempWebGLIntBuffers", "GL", "AL", "GLUT", "EGL", "GLEW", "IDBStore", "SDL", "SDL_gfx", "GLFW", "print", "printErr", "jstoi_s", "WebGPU", "emwgpuStringToInt_BufferMapState", "emwgpuStringToInt_CompilationMessageType", "emwgpuStringToInt_DeviceLostReason", "emwgpuStringToInt_FeatureName", "emwgpuStringToInt_PreferredFormat" ];

unexportedSymbols.forEach(unexportedRuntimeSymbol);

// End runtime exports
// Begin JS library exports
// End JS library exports
// end include: postlibrary.js
function checkIncomingModuleAPI() {
  ignoredModuleProp("fetchSettings");
  ignoredModuleProp("logReadFiles");
  ignoredModuleProp("loadSplitModule");
  ignoredModuleProp("onMalloc");
  ignoredModuleProp("onRealloc");
  ignoredModuleProp("onFree");
  ignoredModuleProp("onSbrkGrow");
}

function mouse_x() {
  return window.__mx || 0;
}

function mouse_y() {
  return window.__my || 0;
}

function sim_started() {
  if (window.__started === undefined) {
    window.__started = 0;
    window.addEventListener("keydown", function(e) {
      if (e.key === "Enter") window.__started = 1;
    });
  }
  return window.__started;
}

// Imports from the Wasm binary.
var _malloc = makeInvalidEarlyAccess("_malloc");

var _free = makeInvalidEarlyAccess("_free");

var _fflush = makeInvalidEarlyAccess("_fflush");

var _main = Module["_main"] = makeInvalidEarlyAccess("_main");

var _emwgpuCreateBindGroup = makeInvalidEarlyAccess("_emwgpuCreateBindGroup");

var _emwgpuCreateBindGroupLayout = makeInvalidEarlyAccess("_emwgpuCreateBindGroupLayout");

var _emwgpuCreateCommandBuffer = makeInvalidEarlyAccess("_emwgpuCreateCommandBuffer");

var _emwgpuCreateCommandEncoder = makeInvalidEarlyAccess("_emwgpuCreateCommandEncoder");

var _emwgpuCreateComputePassEncoder = makeInvalidEarlyAccess("_emwgpuCreateComputePassEncoder");

var _emwgpuCreateComputePipeline = makeInvalidEarlyAccess("_emwgpuCreateComputePipeline");

var _emwgpuCreatePipelineLayout = makeInvalidEarlyAccess("_emwgpuCreatePipelineLayout");

var _emwgpuCreateQuerySet = makeInvalidEarlyAccess("_emwgpuCreateQuerySet");

var _emwgpuCreateRenderBundle = makeInvalidEarlyAccess("_emwgpuCreateRenderBundle");

var _emwgpuCreateRenderBundleEncoder = makeInvalidEarlyAccess("_emwgpuCreateRenderBundleEncoder");

var _emwgpuCreateRenderPassEncoder = makeInvalidEarlyAccess("_emwgpuCreateRenderPassEncoder");

var _emwgpuCreateRenderPipeline = makeInvalidEarlyAccess("_emwgpuCreateRenderPipeline");

var _emwgpuCreateSampler = makeInvalidEarlyAccess("_emwgpuCreateSampler");

var _emwgpuCreateSurface = makeInvalidEarlyAccess("_emwgpuCreateSurface");

var _emwgpuCreateTexture = makeInvalidEarlyAccess("_emwgpuCreateTexture");

var _emwgpuCreateTextureView = makeInvalidEarlyAccess("_emwgpuCreateTextureView");

var _emwgpuCreateAdapter = makeInvalidEarlyAccess("_emwgpuCreateAdapter");

var _emwgpuCreateBuffer = makeInvalidEarlyAccess("_emwgpuCreateBuffer");

var _emwgpuCreateDevice = makeInvalidEarlyAccess("_emwgpuCreateDevice");

var _emwgpuCreateQueue = makeInvalidEarlyAccess("_emwgpuCreateQueue");

var _emwgpuCreateShaderModule = makeInvalidEarlyAccess("_emwgpuCreateShaderModule");

var _emwgpuOnCompilationInfoCompleted = makeInvalidEarlyAccess("_emwgpuOnCompilationInfoCompleted");

var _emwgpuOnCreateComputePipelineCompleted = makeInvalidEarlyAccess("_emwgpuOnCreateComputePipelineCompleted");

var _emwgpuOnCreateRenderPipelineCompleted = makeInvalidEarlyAccess("_emwgpuOnCreateRenderPipelineCompleted");

var _emwgpuOnDeviceLostCompleted = makeInvalidEarlyAccess("_emwgpuOnDeviceLostCompleted");

var _emwgpuOnMapAsyncCompleted = makeInvalidEarlyAccess("_emwgpuOnMapAsyncCompleted");

var _emwgpuOnPopErrorScopeCompleted = makeInvalidEarlyAccess("_emwgpuOnPopErrorScopeCompleted");

var _emwgpuOnRequestAdapterCompleted = makeInvalidEarlyAccess("_emwgpuOnRequestAdapterCompleted");

var _emwgpuOnRequestDeviceCompleted = makeInvalidEarlyAccess("_emwgpuOnRequestDeviceCompleted");

var _emwgpuOnWorkDoneCompleted = makeInvalidEarlyAccess("_emwgpuOnWorkDoneCompleted");

var _emwgpuOnUncapturedError = makeInvalidEarlyAccess("_emwgpuOnUncapturedError");

var _emscripten_stack_get_end = makeInvalidEarlyAccess("_emscripten_stack_get_end");

var _emscripten_stack_get_base = makeInvalidEarlyAccess("_emscripten_stack_get_base");

var _strerror = makeInvalidEarlyAccess("_strerror");

var _sbrk = makeInvalidEarlyAccess("_sbrk");

var _memalign = makeInvalidEarlyAccess("_memalign");

var _emscripten_get_sbrk_ptr = makeInvalidEarlyAccess("_emscripten_get_sbrk_ptr");

var _emscripten_stack_init = makeInvalidEarlyAccess("_emscripten_stack_init");

var _emscripten_stack_get_free = makeInvalidEarlyAccess("_emscripten_stack_get_free");

var __emscripten_stack_restore = makeInvalidEarlyAccess("__emscripten_stack_restore");

var __emscripten_stack_alloc = makeInvalidEarlyAccess("__emscripten_stack_alloc");

var _emscripten_stack_get_current = makeInvalidEarlyAccess("_emscripten_stack_get_current");

var ___set_stack_limits = Module["___set_stack_limits"] = makeInvalidEarlyAccess("___set_stack_limits");

var memory = makeInvalidEarlyAccess("memory");

var __indirect_function_table = makeInvalidEarlyAccess("__indirect_function_table");

var wasmMemory = makeInvalidEarlyAccess("wasmMemory");

var wasmTable = makeInvalidEarlyAccess("wasmTable");

function assignWasmExports(wasmExports) {
  assert(typeof wasmExports["malloc"] != "undefined", "missing Wasm export: malloc");
  assert(typeof wasmExports["free"] != "undefined", "missing Wasm export: free");
  assert(typeof wasmExports["fflush"] != "undefined", "missing Wasm export: fflush");
  assert(typeof wasmExports["main"] != "undefined", "missing Wasm export: main");
  assert(typeof wasmExports["emwgpuCreateBindGroup"] != "undefined", "missing Wasm export: emwgpuCreateBindGroup");
  assert(typeof wasmExports["emwgpuCreateBindGroupLayout"] != "undefined", "missing Wasm export: emwgpuCreateBindGroupLayout");
  assert(typeof wasmExports["emwgpuCreateCommandBuffer"] != "undefined", "missing Wasm export: emwgpuCreateCommandBuffer");
  assert(typeof wasmExports["emwgpuCreateCommandEncoder"] != "undefined", "missing Wasm export: emwgpuCreateCommandEncoder");
  assert(typeof wasmExports["emwgpuCreateComputePassEncoder"] != "undefined", "missing Wasm export: emwgpuCreateComputePassEncoder");
  assert(typeof wasmExports["emwgpuCreateComputePipeline"] != "undefined", "missing Wasm export: emwgpuCreateComputePipeline");
  assert(typeof wasmExports["emwgpuCreatePipelineLayout"] != "undefined", "missing Wasm export: emwgpuCreatePipelineLayout");
  assert(typeof wasmExports["emwgpuCreateQuerySet"] != "undefined", "missing Wasm export: emwgpuCreateQuerySet");
  assert(typeof wasmExports["emwgpuCreateRenderBundle"] != "undefined", "missing Wasm export: emwgpuCreateRenderBundle");
  assert(typeof wasmExports["emwgpuCreateRenderBundleEncoder"] != "undefined", "missing Wasm export: emwgpuCreateRenderBundleEncoder");
  assert(typeof wasmExports["emwgpuCreateRenderPassEncoder"] != "undefined", "missing Wasm export: emwgpuCreateRenderPassEncoder");
  assert(typeof wasmExports["emwgpuCreateRenderPipeline"] != "undefined", "missing Wasm export: emwgpuCreateRenderPipeline");
  assert(typeof wasmExports["emwgpuCreateSampler"] != "undefined", "missing Wasm export: emwgpuCreateSampler");
  assert(typeof wasmExports["emwgpuCreateSurface"] != "undefined", "missing Wasm export: emwgpuCreateSurface");
  assert(typeof wasmExports["emwgpuCreateTexture"] != "undefined", "missing Wasm export: emwgpuCreateTexture");
  assert(typeof wasmExports["emwgpuCreateTextureView"] != "undefined", "missing Wasm export: emwgpuCreateTextureView");
  assert(typeof wasmExports["emwgpuCreateAdapter"] != "undefined", "missing Wasm export: emwgpuCreateAdapter");
  assert(typeof wasmExports["emwgpuCreateBuffer"] != "undefined", "missing Wasm export: emwgpuCreateBuffer");
  assert(typeof wasmExports["emwgpuCreateDevice"] != "undefined", "missing Wasm export: emwgpuCreateDevice");
  assert(typeof wasmExports["emwgpuCreateQueue"] != "undefined", "missing Wasm export: emwgpuCreateQueue");
  assert(typeof wasmExports["emwgpuCreateShaderModule"] != "undefined", "missing Wasm export: emwgpuCreateShaderModule");
  assert(typeof wasmExports["emwgpuOnCompilationInfoCompleted"] != "undefined", "missing Wasm export: emwgpuOnCompilationInfoCompleted");
  assert(typeof wasmExports["emwgpuOnCreateComputePipelineCompleted"] != "undefined", "missing Wasm export: emwgpuOnCreateComputePipelineCompleted");
  assert(typeof wasmExports["emwgpuOnCreateRenderPipelineCompleted"] != "undefined", "missing Wasm export: emwgpuOnCreateRenderPipelineCompleted");
  assert(typeof wasmExports["emwgpuOnDeviceLostCompleted"] != "undefined", "missing Wasm export: emwgpuOnDeviceLostCompleted");
  assert(typeof wasmExports["emwgpuOnMapAsyncCompleted"] != "undefined", "missing Wasm export: emwgpuOnMapAsyncCompleted");
  assert(typeof wasmExports["emwgpuOnPopErrorScopeCompleted"] != "undefined", "missing Wasm export: emwgpuOnPopErrorScopeCompleted");
  assert(typeof wasmExports["emwgpuOnRequestAdapterCompleted"] != "undefined", "missing Wasm export: emwgpuOnRequestAdapterCompleted");
  assert(typeof wasmExports["emwgpuOnRequestDeviceCompleted"] != "undefined", "missing Wasm export: emwgpuOnRequestDeviceCompleted");
  assert(typeof wasmExports["emwgpuOnWorkDoneCompleted"] != "undefined", "missing Wasm export: emwgpuOnWorkDoneCompleted");
  assert(typeof wasmExports["emwgpuOnUncapturedError"] != "undefined", "missing Wasm export: emwgpuOnUncapturedError");
  assert(typeof wasmExports["emscripten_stack_get_end"] != "undefined", "missing Wasm export: emscripten_stack_get_end");
  assert(typeof wasmExports["emscripten_stack_get_base"] != "undefined", "missing Wasm export: emscripten_stack_get_base");
  assert(typeof wasmExports["strerror"] != "undefined", "missing Wasm export: strerror");
  assert(typeof wasmExports["sbrk"] != "undefined", "missing Wasm export: sbrk");
  assert(typeof wasmExports["memalign"] != "undefined", "missing Wasm export: memalign");
  assert(typeof wasmExports["emscripten_get_sbrk_ptr"] != "undefined", "missing Wasm export: emscripten_get_sbrk_ptr");
  assert(typeof wasmExports["emscripten_stack_init"] != "undefined", "missing Wasm export: emscripten_stack_init");
  assert(typeof wasmExports["emscripten_stack_get_free"] != "undefined", "missing Wasm export: emscripten_stack_get_free");
  assert(typeof wasmExports["_emscripten_stack_restore"] != "undefined", "missing Wasm export: _emscripten_stack_restore");
  assert(typeof wasmExports["_emscripten_stack_alloc"] != "undefined", "missing Wasm export: _emscripten_stack_alloc");
  assert(typeof wasmExports["emscripten_stack_get_current"] != "undefined", "missing Wasm export: emscripten_stack_get_current");
  assert(typeof wasmExports["__set_stack_limits"] != "undefined", "missing Wasm export: __set_stack_limits");
  assert(typeof wasmExports["memory"] != "undefined", "missing Wasm export: memory");
  assert(typeof wasmExports["__indirect_function_table"] != "undefined", "missing Wasm export: __indirect_function_table");
  _malloc = createExportWrapper("malloc", 1);
  _free = createExportWrapper("free", 1);
  _fflush = createExportWrapper("fflush", 1);
  _main = Module["_main"] = createExportWrapper("main", 3);
  _emwgpuCreateBindGroup = createExportWrapper("emwgpuCreateBindGroup", 1);
  _emwgpuCreateBindGroupLayout = createExportWrapper("emwgpuCreateBindGroupLayout", 1);
  _emwgpuCreateCommandBuffer = createExportWrapper("emwgpuCreateCommandBuffer", 1);
  _emwgpuCreateCommandEncoder = createExportWrapper("emwgpuCreateCommandEncoder", 1);
  _emwgpuCreateComputePassEncoder = createExportWrapper("emwgpuCreateComputePassEncoder", 1);
  _emwgpuCreateComputePipeline = createExportWrapper("emwgpuCreateComputePipeline", 1);
  _emwgpuCreatePipelineLayout = createExportWrapper("emwgpuCreatePipelineLayout", 1);
  _emwgpuCreateQuerySet = createExportWrapper("emwgpuCreateQuerySet", 1);
  _emwgpuCreateRenderBundle = createExportWrapper("emwgpuCreateRenderBundle", 1);
  _emwgpuCreateRenderBundleEncoder = createExportWrapper("emwgpuCreateRenderBundleEncoder", 1);
  _emwgpuCreateRenderPassEncoder = createExportWrapper("emwgpuCreateRenderPassEncoder", 1);
  _emwgpuCreateRenderPipeline = createExportWrapper("emwgpuCreateRenderPipeline", 1);
  _emwgpuCreateSampler = createExportWrapper("emwgpuCreateSampler", 1);
  _emwgpuCreateSurface = createExportWrapper("emwgpuCreateSurface", 1);
  _emwgpuCreateTexture = createExportWrapper("emwgpuCreateTexture", 1);
  _emwgpuCreateTextureView = createExportWrapper("emwgpuCreateTextureView", 1);
  _emwgpuCreateAdapter = createExportWrapper("emwgpuCreateAdapter", 1);
  _emwgpuCreateBuffer = createExportWrapper("emwgpuCreateBuffer", 2);
  _emwgpuCreateDevice = createExportWrapper("emwgpuCreateDevice", 2);
  _emwgpuCreateQueue = createExportWrapper("emwgpuCreateQueue", 1);
  _emwgpuCreateShaderModule = createExportWrapper("emwgpuCreateShaderModule", 1);
  _emwgpuOnCompilationInfoCompleted = createExportWrapper("emwgpuOnCompilationInfoCompleted", 3);
  _emwgpuOnCreateComputePipelineCompleted = createExportWrapper("emwgpuOnCreateComputePipelineCompleted", 4);
  _emwgpuOnCreateRenderPipelineCompleted = createExportWrapper("emwgpuOnCreateRenderPipelineCompleted", 4);
  _emwgpuOnDeviceLostCompleted = createExportWrapper("emwgpuOnDeviceLostCompleted", 3);
  _emwgpuOnMapAsyncCompleted = createExportWrapper("emwgpuOnMapAsyncCompleted", 3);
  _emwgpuOnPopErrorScopeCompleted = createExportWrapper("emwgpuOnPopErrorScopeCompleted", 4);
  _emwgpuOnRequestAdapterCompleted = createExportWrapper("emwgpuOnRequestAdapterCompleted", 4);
  _emwgpuOnRequestDeviceCompleted = createExportWrapper("emwgpuOnRequestDeviceCompleted", 4);
  _emwgpuOnWorkDoneCompleted = createExportWrapper("emwgpuOnWorkDoneCompleted", 2);
  _emwgpuOnUncapturedError = createExportWrapper("emwgpuOnUncapturedError", 3);
  _emscripten_stack_get_end = wasmExports["emscripten_stack_get_end"];
  _emscripten_stack_get_base = wasmExports["emscripten_stack_get_base"];
  _strerror = createExportWrapper("strerror", 1);
  _sbrk = createExportWrapper("sbrk", 1);
  _memalign = createExportWrapper("memalign", 2);
  _emscripten_get_sbrk_ptr = wasmExports["emscripten_get_sbrk_ptr"];
  _emscripten_stack_init = wasmExports["emscripten_stack_init"];
  _emscripten_stack_get_free = wasmExports["emscripten_stack_get_free"];
  __emscripten_stack_restore = wasmExports["_emscripten_stack_restore"];
  __emscripten_stack_alloc = wasmExports["_emscripten_stack_alloc"];
  _emscripten_stack_get_current = wasmExports["emscripten_stack_get_current"];
  ___set_stack_limits = Module["___set_stack_limits"] = createExportWrapper("__set_stack_limits", 2);
  memory = wasmMemory = wasmExports["memory"];
  __indirect_function_table = wasmTable = wasmExports["__indirect_function_table"];
}

var wasmImports = {
  /** @export */ __assert_fail: ___assert_fail,
  /** @export */ __call_sighandler: ___call_sighandler,
  /** @export */ __cxa_throw: ___cxa_throw,
  /** @export */ __handle_stack_overflow: ___handle_stack_overflow,
  /** @export */ _abort_js: __abort_js,
  /** @export */ _emscripten_runtime_keepalive_clear: __emscripten_runtime_keepalive_clear,
  /** @export */ alignfault,
  /** @export */ clock_time_get: _clock_time_get,
  /** @export */ emscripten_get_heap_max: _emscripten_get_heap_max,
  /** @export */ emscripten_get_now: _emscripten_get_now,
  /** @export */ emscripten_has_asyncify: _emscripten_has_asyncify,
  /** @export */ emscripten_resize_heap: _emscripten_resize_heap,
  /** @export */ emscripten_set_main_loop: _emscripten_set_main_loop,
  /** @export */ emwgpuAdapterRequestDevice: _emwgpuAdapterRequestDevice,
  /** @export */ emwgpuDelete: _emwgpuDelete,
  /** @export */ emwgpuDeviceCreateBuffer: _emwgpuDeviceCreateBuffer,
  /** @export */ emwgpuDeviceCreateShaderModule: _emwgpuDeviceCreateShaderModule,
  /** @export */ emwgpuDeviceDestroy: _emwgpuDeviceDestroy,
  /** @export */ emwgpuGetPreferredFormat: _emwgpuGetPreferredFormat,
  /** @export */ emwgpuInstanceRequestAdapter: _emwgpuInstanceRequestAdapter,
  /** @export */ exit: _exit,
  /** @export */ fd_close: _fd_close,
  /** @export */ fd_seek: _fd_seek,
  /** @export */ fd_write: _fd_write,
  /** @export */ mouse_x,
  /** @export */ mouse_y,
  /** @export */ proc_exit: _proc_exit,
  /** @export */ segfault,
  /** @export */ sim_started,
  /** @export */ wgpuCommandEncoderBeginRenderPass: _wgpuCommandEncoderBeginRenderPass,
  /** @export */ wgpuCommandEncoderFinish: _wgpuCommandEncoderFinish,
  /** @export */ wgpuDeviceCreateBindGroup: _wgpuDeviceCreateBindGroup,
  /** @export */ wgpuDeviceCreateBindGroupLayout: _wgpuDeviceCreateBindGroupLayout,
  /** @export */ wgpuDeviceCreateCommandEncoder: _wgpuDeviceCreateCommandEncoder,
  /** @export */ wgpuDeviceCreatePipelineLayout: _wgpuDeviceCreatePipelineLayout,
  /** @export */ wgpuDeviceCreateRenderPipeline: _wgpuDeviceCreateRenderPipeline,
  /** @export */ wgpuDeviceCreateTexture: _wgpuDeviceCreateTexture,
  /** @export */ wgpuInstanceCreateSurface: _wgpuInstanceCreateSurface,
  /** @export */ wgpuQueueSubmit: _wgpuQueueSubmit,
  /** @export */ wgpuQueueWriteBuffer: _wgpuQueueWriteBuffer,
  /** @export */ wgpuRenderPassEncoderDrawIndexed: _wgpuRenderPassEncoderDrawIndexed,
  /** @export */ wgpuRenderPassEncoderEnd: _wgpuRenderPassEncoderEnd,
  /** @export */ wgpuRenderPassEncoderSetBindGroup: _wgpuRenderPassEncoderSetBindGroup,
  /** @export */ wgpuRenderPassEncoderSetIndexBuffer: _wgpuRenderPassEncoderSetIndexBuffer,
  /** @export */ wgpuRenderPassEncoderSetPipeline: _wgpuRenderPassEncoderSetPipeline,
  /** @export */ wgpuRenderPassEncoderSetVertexBuffer: _wgpuRenderPassEncoderSetVertexBuffer,
  /** @export */ wgpuSurfaceConfigure: _wgpuSurfaceConfigure,
  /** @export */ wgpuSurfaceGetCurrentTexture: _wgpuSurfaceGetCurrentTexture,
  /** @export */ wgpuTextureCreateView: _wgpuTextureCreateView
};

// include: postamble.js
// === Auto-generated postamble setup entry stuff ===
var calledRun;

function callMain(args = []) {
  assert(runDependencies == 0, 'cannot call main when async dependencies remain! (listen on Module["onRuntimeInitialized"])');
  assert(typeof onPreRuns === "undefined" || onPreRuns.length == 0, "cannot call main when preRun functions remain to be called");
  var entryFunction = _main;
  args.unshift(thisProgram);
  var argc = args.length;
  var argv = stackAlloc((argc + 1) * 4);
  var argv_ptr = argv;
  for (var arg of args) {
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((argv_ptr) >> 2), "storing")] = stringToUTF8OnStack(arg);
    argv_ptr += 4;
  }
  HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((argv_ptr) >> 2), "storing")] = 0;
  try {
    var ret = entryFunction(argc, argv);
    // if we're not running an evented main loop, it's time to exit
    exitJS(ret, /* implicit = */ true);
    return ret;
  } catch (e) {
    return handleException(e);
  }
}

function stackCheckInit() {
  // This is normally called automatically during __wasm_call_ctors but need to
  // get these values before even running any of the ctors so we call it redundantly
  // here.
  _emscripten_stack_init();
  // TODO(sbc): Move writeStackCookie to native to to avoid this.
  writeStackCookie();
}

function run(args = arguments_) {
  if (runDependencies > 0) {
    dependenciesFulfilled = run;
    return;
  }
  stackCheckInit();
  preRun();
  // a preRun added a dependency, run will be called later
  if (runDependencies > 0) {
    dependenciesFulfilled = run;
    return;
  }
  function doRun() {
    // run may have just been called through dependencies being fulfilled just in this very frame,
    // or while the async setStatus time below was happening
    assert(!calledRun);
    calledRun = true;
    Module["calledRun"] = true;
    if (ABORT) return;
    initRuntime();
    preMain();
    Module["onRuntimeInitialized"]?.();
    consumedModuleProp("onRuntimeInitialized");
    var noInitialRun = Module["noInitialRun"] || false;
    if (!noInitialRun) callMain(args);
    postRun();
  }
  if (Module["setStatus"]) {
    Module["setStatus"]("Running...");
    setTimeout(() => {
      setTimeout(() => Module["setStatus"](""), 1);
      doRun();
    }, 1);
  } else {
    doRun();
  }
  checkStackCookie();
}

function checkUnflushedContent() {
  // Compiler settings do not allow exiting the runtime, so flushing
  // the streams is not possible. but in ASSERTIONS mode we check
  // if there was something to flush, and if so tell the user they
  // should request that the runtime be exitable.
  // Normally we would not even include flush() at all, but in ASSERTIONS
  // builds we do so just for this check, and here we see if there is any
  // content to flush, that is, we check if there would have been
  // something a non-ASSERTIONS build would have not seen.
  // How we flush the streams depends on whether we are in SYSCALLS_REQUIRE_FILESYSTEM=0
  // mode (which has its own special function for this; otherwise, all
  // the code is inside libc)
  var oldOut = out;
  var oldErr = err;
  var has = false;
  out = err = x => {
    has = true;
  };
  try {
    // it doesn't matter if it fails
    flush_NO_FILESYSTEM();
  } catch (e) {}
  out = oldOut;
  err = oldErr;
  if (has) {
    warnOnce("stdio streams had content in them that was not flushed. you should set EXIT_RUNTIME to 1 (see the Emscripten FAQ), or make sure to emit a newline when you printf etc.");
    warnOnce("(this may also be due to not including full filesystem support - try building with -sFORCE_FILESYSTEM)");
  }
}

var wasmExports;

// With async instantation wasmExports is assigned asynchronously when the
// instance is received.
createWasm();

run();
