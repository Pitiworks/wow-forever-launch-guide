"""Run isolated addon tests using the system LuaJIT (WoW-compatible Lua 5.1).

No pip dependencies or Lua executable required; uses the installed shared library.
Run from the repository root: python3 tools/run_lua_tests.py
"""
import ctypes
import ctypes.util
import os
from pathlib import Path


def run(path, execute):
    lua = ctypes.CDLL(ctypes.util.find_library("luajit-5.1") or "libluajit-5.1.so.2")
    lua.luaL_newstate.restype = ctypes.c_void_p
    lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
    lua.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    lua.luaL_loadfile.restype = ctypes.c_int
    lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
    lua.lua_pcall.restype = ctypes.c_int
    lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    lua.lua_tolstring.restype = ctypes.c_char_p
    lua.lua_close.argtypes = [ctypes.c_void_p]
    state = lua.luaL_newstate()
    if not state:
        raise RuntimeError("Cannot allocate Lua state")
    try:
        lua.luaL_openlibs(state)
        status = lua.luaL_loadfile(state, str(path).encode())
        if status == 0 and execute:
            status = lua.lua_pcall(state, 0, 0, 0)
        if status:
            error = lua.lua_tolstring(state, -1, None)
            raise RuntimeError(f"{path}: {error.decode() if error else 'Lua error'}")
    finally:
        lua.lua_close(state)


if __name__ == "__main__":
    sources = sorted(Path("addon").rglob("*.lua"))
    specs = sorted(Path("tests").glob("*_spec.lua"))
    for source in sources:
        run(source, False)
    for spec in specs:
        run(spec, True)
    if os.environ.get("WFLG_QUESTIEDB_PATH"):
        run(Path("tests/integration_questiedb.lua"), True)
    print(f"PASS: {len(sources)} Lua 5.1 syntax checks, {len(specs)} isolated test suites")
