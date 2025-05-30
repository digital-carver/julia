# This file is a part of Julia. License is MIT: https://julialang.org/license

## File Operations (Libuv-based) ##

module Filesystem

"""
    JL_O_APPEND
    JL_O_ASYNC
    JL_O_CLOEXEC
    JL_O_CREAT
    JL_O_DIRECT
    JL_O_DIRECTORY
    JL_O_DSYNC
    JL_O_EXCL
    JL_O_FSYNC
    JL_O_LARGEFILE
    JL_O_NDELAY
    JL_O_NOATIME
    JL_O_NOCTTY
    JL_O_NOFOLLOW
    JL_O_NONBLOCK
    JL_O_PATH
    JL_O_RANDOM
    JL_O_RDONLY
    JL_O_RDWR
    JL_O_RSYNC
    JL_O_SEQUENTIAL
    JL_O_SHORT_LIVED
    JL_O_SYNC
    JL_O_TEMPORARY
    JL_O_TMPFILE
    JL_O_TRUNC
    JL_O_WRONLY

Enum constant for the `open` syscall, where `JL_O_*` corresponds to the `O_*` constant.
See [the libuv docs](https://docs.libuv.org/en/v1.x/fs.html#file-open-constants) for more details.
"""
(:JL_O_APPEND, :JL_O_ASYNC, :JL_O_CLOEXEC, :JL_O_CREAT, :JL_O_DIRECT,
 :JL_O_DIRECTORY, :JL_O_DSYNC, :JL_O_EXCL, :JL_O_FSYNC, :JL_O_LARGEFILE,
 :JL_O_NOATIME, :JL_O_NOCTTY, :JL_O_NDELAY, :JL_O_NOFOLLOW, :JL_O_NONBLOCK,
 :JL_O_PATH, :JL_O_RANDOM, :JL_O_RDONLY, :JL_O_RDWR, :JL_O_RSYNC,
 :JL_O_SEQUENTIAL, :JL_O_SHORT_LIVED, :JL_O_SYNC, :JL_O_TEMPORARY,
 :JL_O_TMPFILE, :JL_O_TRUNC, :JL_O_WRONLY)

const S_IFDIR  = 0o040000  # directory
const S_IFCHR  = 0o020000  # character device
const S_IFBLK  = 0o060000  # block device
const S_IFREG  = 0o100000  # regular file
const S_IFIFO  = 0o010000  # fifo (named pipe)
const S_IFLNK  = 0o120000  # symbolic link
const S_IFSOCK = 0o140000  # socket file
const S_IFMT   = 0o170000

const S_ISUID = 0o4000  # set UID bit
const S_ISGID = 0o2000  # set GID bit
const S_ENFMT = S_ISGID # file locking enforcement
const S_ISVTX = 0o1000  # sticky bit

const S_IRUSR = 0o0400  # read by owner
const S_IWUSR = 0o0200  # write by owner
const S_IXUSR = 0o0100  # execute by owner
const S_IRWXU = 0o0700  # mask for owner permissions
const S_IRGRP = 0o0040  # read by group
const S_IWGRP = 0o0020  # write by group
const S_IXGRP = 0o0010  # execute by group
const S_IRWXG = 0o0070  # mask for group permissions
const S_IROTH = 0o0004  # read by other
const S_IWOTH = 0o0002  # write by other
const S_IXOTH = 0o0001  # execute by other
const S_IRWXO = 0o0007  # mask for other permissions

"""
    S_IRUSR
    S_IWUSR
    S_IXUSR
    S_IRGRP
    S_IWGRP
    S_IXGRP
    S_IROTH
    S_IWOTH
    S_IXOTH

Constants for file access permission bits.
The general structure is `S_I[permission][class]`
where `permission` is `R` for read, `W` for write, and `X` for execute,
and `class` is `USR` for user/owner, `GRP` for group, and `OTH` for other.
"""
(:S_IRUSR, :S_IWUSR, :S_IXUSR, :S_IRGRP, :S_IWGRP, :S_IXGRP, :S_IROTH, :S_IWOTH, :S_IXOTH)

"""
    S_IRWXU
    S_IRWXG
    S_IRWXO

Constants for file access permission masks, i.e. the combination of read, write,
and execute permissions for a class.
The general structure is `S_IRWX[class]`
where `class` is `U` for user/owner, `G` for group, and `O` for other.
"""
(:S_IRWXU, :S_IRWXG, :S_IRWXO)

export File,
       StatStruct,
       # open,
       futime,
       write,
       JL_O_WRONLY,
       JL_O_RDONLY,
       JL_O_RDWR,
       JL_O_APPEND,
       JL_O_CREAT,
       JL_O_EXCL,
       JL_O_TRUNC,
       JL_O_TEMPORARY,
       JL_O_SHORT_LIVED,
       JL_O_SEQUENTIAL,
       JL_O_RANDOM,
       JL_O_NOCTTY,
       JL_O_NONBLOCK,
       JL_O_NDELAY,
       JL_O_SYNC,
       JL_O_FSYNC,
       JL_O_ASYNC,
       JL_O_LARGEFILE,
       JL_O_DIRECTORY,
       JL_O_NOFOLLOW,
       JL_O_CLOEXEC,
       JL_O_DIRECT,
       JL_O_NOATIME,
       JL_O_PATH,
       JL_O_TMPFILE,
       JL_O_DSYNC,
       JL_O_RSYNC,
       S_IRUSR, S_IWUSR, S_IXUSR, S_IRWXU,
       S_IRGRP, S_IWGRP, S_IXGRP, S_IRWXG,
       S_IROTH, S_IWOTH, S_IXOTH, S_IRWXO

import .Base:
    IOError, _UVError, _sizeof_uv_fs, check_open, close, closewrite, eof, eventloop, fd, isopen,
    bytesavailable, position, read, read!, readbytes!, readavailable, seek, seekend, show,
    skip, stat, unsafe_read, unsafe_write, write, transcode, uv_error, _uv_error,
    setup_stdio, rawhandle, OS_HANDLE, INVALID_OS_HANDLE, windowserror, filesize,
    isexecutable, isreadable, iswritable, MutableDenseArrayType, truncate

import .Base.RefValue

if Sys.iswindows()
    import .Base: cwstring
end

# Average buffer size including null terminator for several filesystem operations.
# On Windows we use the MAX_PATH = 260 value on Win32.
const AVG_PATH = Sys.iswindows() ? 260 : 512

# helper function to clean up libuv request
uv_fs_req_cleanup(req) = ccall(:uv_fs_req_cleanup, Cvoid, (Ptr{Cvoid},), req)

include("path.jl")
include("stat.jl")
include("file.jl")
include(string(Base.BUILDROOT, "file_constants.jl"))  # include($BUILDROOT/base/file_constants.jl)

## Operations with File (fd) objects ##

abstract type AbstractFile <: IO end

mutable struct File <: AbstractFile
    open::Bool
    handle::OS_HANDLE
    File(fd::OS_HANDLE) = new(true, fd)
end
if OS_HANDLE !== RawFD
    File(fd::RawFD) = File(Libc._get_osfhandle(fd)) # TODO: calling close would now destroy the wrong handle
end

rawhandle(file::File) = file.handle
setup_stdio(file::File, ::Bool) = (file, false)

# Filesystem.open, not Base.open
function open(path::AbstractString, flags::Integer, mode::Integer=0)
    req = Libc.malloc(_sizeof_uv_fs)
    local handle
    try
        ret = ccall(:uv_fs_open, Int32,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Cstring, Int32, Int32, Ptr{Cvoid}),
                    C_NULL, req, path, flags, mode, C_NULL)
        handle = ccall(:uv_fs_get_result, Cssize_t, (Ptr{Cvoid},), req)
        uv_fs_req_cleanup(req)
        ret < 0 && uv_error("open($(repr(path)), $flags, $mode)", ret)
    finally # conversion to Cstring could cause an exception
        Libc.free(req)
    end
    return File(OS_HANDLE(@static Sys.iswindows() ? Ptr{Cvoid}(handle) : Cint(handle)))
end

isopen(f::File) = f.open

function check_open(f::File)
    if !isopen(f)
        throw(ArgumentError("file is closed"))
    end
end

function close(f::File)
    if isopen(f)
        f.open = false
        err = ccall(:jl_fs_close, Int32, (OS_HANDLE,), f.handle)
        f.handle = INVALID_OS_HANDLE
        uv_error("close", err)
    end
    nothing
end

closewrite(f::File) = nothing

# sendfile is the most efficient way to copy from a file descriptor
function sendfile(dst::File, src::File, src_offset::Int64, bytes::Int)
    check_open(dst)
    check_open(src)
    while true
        result = ccall(:jl_fs_sendfile, Int32, (OS_HANDLE, OS_HANDLE, Int64, Csize_t),
                       src.handle, dst.handle, src_offset, bytes)
        uv_error("sendfile", result)
        nsent = result
        bytes -= nsent
        src_offset += nsent
        bytes <= 0 && break
    end
    nothing
end

function unsafe_write(f::File, buf::Ptr{UInt8}, len::UInt, offset::Int64=Int64(-1))
    check_open(f)
    err = ccall(:jl_fs_write, Int32, (OS_HANDLE, Ptr{UInt8}, Csize_t, Int64),
                f.handle, buf, len, offset)
    uv_error("write", err)
    return len
end

write(f::File, c::UInt8) = write(f, Ref{UInt8}(c))

function truncate(f::File, n::Integer)
    check_open(f)
    req = Libc.malloc(_sizeof_uv_fs)
    err = ccall(:uv_fs_ftruncate, Int32,
                (Ptr{Cvoid}, Ptr{Cvoid}, OS_HANDLE, Int64, Ptr{Cvoid}),
                C_NULL, req, f.handle, n, C_NULL)
    Libc.free(req)
    uv_error("ftruncate", err)
    return f
end

function futime(f::File, atime::Float64, mtime::Float64)
    check_open(f)
    req = Libc.malloc(_sizeof_uv_fs)
    err = ccall(:uv_fs_futime, Int32,
                (Ptr{Cvoid}, Ptr{Cvoid}, OS_HANDLE, Float64, Float64, Ptr{Cvoid}),
                C_NULL, req, f.handle, atime, mtime, C_NULL)
    Libc.free(req)
    uv_error("futime", err)
    return f
end

function read(f::File, ::Type{UInt8})
    check_open(f)
    p = Ref{UInt8}()
    ret = ccall(:jl_fs_read, Int32, (OS_HANDLE, Ptr{Cvoid}, Csize_t),
                f.handle, p, 1)
    uv_error("read", ret)
    @assert ret <= sizeof(p) == 1
    ret < 1 && throw(EOFError())
    return p[] % UInt8
end

function read(f::File, ::Type{Char})
    b0 = read(f, UInt8)
    l = 0x08 * (0x04 - UInt8(leading_ones(b0)))
    c = UInt32(b0) << 24
    if l ≤ 0x10
        s = 16
        while s ≥ l && !eof(f)
            # this works around lack of peek(::File)
            p = position(f)
            b = read(f, UInt8)
            if b & 0xc0 != 0x80
                seek(f, p)
                break
            end
            c |= UInt32(b) << s
            s -= 8
        end
    end
    return reinterpret(Char, c)
end

read(f::File, ::Type{T}) where {T<:AbstractChar} = T(read(f, Char)) # fallback

function unsafe_read(f::File, p::Ptr{UInt8}, nel::UInt)
    check_open(f)
    ret = ccall(:jl_fs_read, Int32, (OS_HANDLE, Ptr{Cvoid}, Csize_t),
                f.handle, p, nel)
    uv_error("read", ret)
    ret == nel || throw(EOFError())
    nothing
end

bytesavailable(f::File) = max(0, filesize(f) - position(f)) # position can be > filesize

eof(f::File) = bytesavailable(f) == 0

function readbytes!(f::File, b::MutableDenseArrayType{UInt8}, nb=length(b))
    nr = min(nb, bytesavailable(f))
    if length(b) < nr
        resize!(b, nr)
    end
    ret = ccall(:jl_fs_read, Int32, (OS_HANDLE, Ptr{Cvoid}, Csize_t),
                f.handle, b, nr)
    uv_error("read", ret)
    return ret
end
read(io::File) = read!(io, Base.StringVector(bytesavailable(io)))
readavailable(io::File) = read(io)
read(io::File, nb::Integer) = read!(io, Base.StringVector(min(nb, bytesavailable(io))))

const SEEK_SET = Int32(0)
const SEEK_CUR = Int32(1)
const SEEK_END = Int32(2)

function seek(f::File, n::Integer)
    ret = ccall(:jl_lseek, Int64, (OS_HANDLE, Int64, Int32), f.handle, n, SEEK_SET)
    ret == -1 && (@static Sys.iswindows() ? windowserror : systemerror)("seek")
    return f
end

function seekend(f::File)
    ret = ccall(:jl_lseek, Int64, (OS_HANDLE, Int64, Int32), f.handle, 0, SEEK_END)
    ret == -1 && (@static Sys.iswindows() ? windowserror : systemerror)("seekend")
    return f
end

function skip(f::File, n::Integer)
    ret = ccall(:jl_lseek, Int64, (OS_HANDLE, Int64, Int32), f.handle, n, SEEK_CUR)
    ret == -1 && (@static Sys.iswindows() ? windowserror : systemerror)("skip")
    return f
end

function position(f::File)
    check_open(f)
    ret = ccall(:jl_lseek, Int64, (OS_HANDLE, Int64, Int32), f.handle, 0, SEEK_CUR)
    ret == -1 && (@static Sys.iswindows() ? windowserror : systemerror)("lseek")
    return ret
end

fd(f::File) = f.handle
stat(f::File) = stat(f.handle)

function touch(f::File)
    @static if Sys.isunix()
        ret = ccall(:futimes, Cint, (Cint, Ptr{Cvoid}), fd(f), C_NULL)
        systemerror(:futimes, ret != 0)
    else
        t = time()
        futime(f, t, t)
    end
    f
end

"""
    isexecutable(path::String)

Return `true` if the given `path` has executable permissions.

!!! note
    This permission may change before the user executes `path`,
    so it is recommended to execute the file and handle the error if that fails,
    rather than calling `isexecutable` first.

!!! note
    Prior to Julia 1.6, this did not correctly interrogate filesystem
    ACLs on Windows, therefore it would return `true` for any
    file.  From Julia 1.6 on, it correctly determines whether the
    file is marked as executable or not.

See also [`ispath`](@ref), [`isreadable`](@ref), [`iswritable`](@ref).
"""
function isexecutable(path::String)
    # We use `access()` and `X_OK` to determine if a given path is
    # executable by the current user.  `X_OK` comes from `unistd.h`.
    X_OK = 0x01
    return ccall(:jl_fs_access, Cint, (Cstring, Cint), path, X_OK) == 0
end
isexecutable(path::AbstractString) = isexecutable(String(path))

"""
    isreadable(path::String)

Return `true` if the access permissions for the given `path` permitted reading by the current user.

!!! note
    This permission may change before the user calls `open`,
    so it is recommended to just call `open` alone and handle the error if that fails,
    rather than calling `isreadable` first.

!!! note
    Currently this function does not correctly interrogate filesystem
    ACLs on Windows, therefore it can return wrong results.

!!! compat "Julia 1.11"
    This function requires at least Julia 1.11.

See also [`ispath`](@ref), [`isexecutable`](@ref), [`iswritable`](@ref).
"""
function isreadable(path::String)
    # We use `access()` and `R_OK` to determine if a given path is
    # readable by the current user.  `R_OK` comes from `unistd.h`.
    R_OK = 0x04
    return ccall(:jl_fs_access, Cint, (Cstring, Cint), path, R_OK) == 0
end
isreadable(path::AbstractString) = isreadable(String(path))

"""
    iswritable(path::String)

Return `true` if the access permissions for the given `path` permitted writing by the current user.

!!! note
    This permission may change before the user calls `open`,
    so it is recommended to just call `open` alone and handle the error if that fails,
    rather than calling `iswritable` first.

!!! note
    Currently this function does not correctly interrogate filesystem
    ACLs on Windows, therefore it can return wrong results.

!!! compat "Julia 1.11"
    This function requires at least Julia 1.11.

See also [`ispath`](@ref), [`isexecutable`](@ref), [`isreadable`](@ref).
"""
function iswritable(path::String)
    # We use `access()` and `W_OK` to determine if a given path is
    # writeable by the current user.  `W_OK` comes from `unistd.h`.
    W_OK = 0x02
    return ccall(:jl_fs_access, Cint, (Cstring, Cint), path, W_OK) == 0
end
iswritable(path::AbstractString) = iswritable(String(path))


end
