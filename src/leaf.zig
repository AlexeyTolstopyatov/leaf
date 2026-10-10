//
// CoffeeLake(c) 2026-*
// LEAF Object Format - rev 1.0.2
//
//!
//! Expecting file layout
//! ```text
//! ┌───────────────────────┐ ┐
//! │ FILE header section │ │ Resident header
//! │ LOAD header section │ │ (loads with app image)
//! ├───────────────────────┤ ┘
//! │ LINK header section │ Non-resident header
//! │ metadata table      │ (will ignored by loader)
//! ├───────────────────────┤
//! │   SECTION TABLE     │ 
//! │ RELOCACTION BLOCKS  │ 
//! ├───────────────────────┤
//! │ 00 01 FF 4D D6 90 20│ File Section bytes
//! │ 33 00 00 03 00 04 FF│ 
//! │ 56 09 DA F0 0B CC 3C│
//! ├───────────────────────┤  
//! │ 03 00 05 DD 0A 5F 4D│ File section bytes
//! ├───────────────────────┤
//! │  .export section    │ Defines by special characteristics
//! ├───────────────────────┤ and markers inside
//! |  .import section    │ 
//! ├───────────────────────┤
//! ├───────────────────────┤
//! │ ???                 │ Under construction
//! └───────────────────────┘
//! ```
//! 
//! The `_offset` postfix fields are file offset values
//! The `_ptr` postfix fields are virtual offsets what depend on the `LOAD::base`
//! 
/// Platform-independent part of the LEAF header is a FILE_HEADER.
/// Lives at the beginning of file.
pub const File = extern struct {
    magic: u32,           // 4
    cpu: CPUArchitecture, // 2
    cpu_word: CPUWordSize,// 1  32 or 64 defines the following loader section
    module: ModuleType,   // 1
    flags: ModuleFlags,   // 4
    strings_offset: u32,  // 4 where the strings table begins
    strings_size: u32,    // 4 size of the strings table
    link_offset: u32,     // 4 offset to the LINK section. 
    pub const MAGIC_LE: u32 = 0x4C454146;
    pub const MAGIC_BE: u32 = 0x4641454C;

    pub const LEAF_VERSION: Version = .{
        .major = 1, 
        .minor = 0, 
        .revision = 2, 
        .build = 0,
    };

    pub fn testMagic(m: u32) bool {
        return m == MAGIC_BE or m == MAGIC_LE;
    }
    pub fn testOfmtVersion(m: Version) bool {
        return Version.eql(m, LEAF_VERSION);
    }
};
///
/// Registered/supported machine word sizes
/// 
pub const CPUWordSize = enum(u8) {
    _32 = 0x20,
    _64 = 0x40,
};

/// Image behaviour flags. Orthogonal to Module kind.
pub const ModuleFlags = packed struct(u32) {
    /// Code is position-independent Ignore the relocation table.
    /// Loader may place image at any base without touching it.
    no_relocs: bool = false,
    /// Image has a valid relocation table and can be rebased.
    pie_capable: bool = false,
    /// Image must be loaded at `Load.base`. Overrides ASLR.
    fixed_base: bool = false,
    /// Kernel-mode image: ring0-only features, no user-mode system calls
    mode: bool = false,
    /// Image carries a valid signature section (required by HVCI-style checks)
    signed: bool = false,
    /// Image carries debug info in a section marked `Kind.Debug`
    debug_info: bool = false,
    _reserved: u26 = 0,
};

/// Variant of the loader block, selected by File.cpu_word.
pub const Load = packed union {
    _32: Load32,
    _64: Load64,
};
/// 
/// Directly by the file section the Loader section is following.
/// if `cpu_word=0x20` in the File section
/// 
pub const Load32 = extern struct {
    base: u32,             // image location 
    size: u32,             // image size
    entry_ptr: u32,
    sections_offset: u32,
    sections_count: u32,
    relocs_offset: u32,
    relocs_count: u32,
};
/// 
/// Directly by the file section the Load64 section is following
/// if `cpu_word=0x40` in the File section.
///   
pub const Load64 = extern struct {
    base: u64,
    size: u64,
    entry_ptr: u64,
    sections_offset: u64,
    sections_count: u64,
    relocs_offset: u64,
    relocs_count: u64,
};
///
/// Runtime section is an addition to the LOAD section and skips by `init.lea`
/// because of unused operating system support.
/// The "rich" binaries from the userland might contain this extension
/// 
pub const Runtime32 = extern struct {
    internal_name_offset: u32,
    exports_offset: u32,
    exports_count: u16,
    imports_offset: u32,
    imports_count: u16,
};
///
/// Runtime section is an addition to the LOAD section and skips by `init.lea`
/// because of unused operating system support.
/// The "rich" binaries from the userland might contain this extension
/// 
pub const Runtime64 = extern struct {
    internal_name_offset: u32,
    exports_offset: u64,
    exports_count: u32,
    imports_offset: u64,
    imports_count: u32,
};

pub const CPUArchitecture = enum(u16) {
    /// None flag tells that image contains untyped/undefined machine code
    /// or might contain pseudocode.
    None = 0,
    IA32 = 1,
    IA32e = 2,
    ARM = 3,
    ARM64 = 4,
    ARM7 = 5,
};

pub const ModuleType = enum(u8) {
    /// Module doesn't load in memory,
    /// loader returns success state but does nothing after module type checking 
    Discarded = 0,
    /// Module `entry_ptr` is a necessary field in the LOAD header,
    /// must be declared and not null.
    Executable = 1,
    /// Module `entry_ptr` is an initialization procedure pointer
    /// which may be missed or ignored by developers, (can be null)
    Library = 2,
    /// If module type checking resolves a driver module, the
    /// `ModuleFlags` must contain a `SIGNED`-bit and a special 
    /// signature must be embedded  
    Driver = 3,
};

pub const Platform = enum(u16) {
    Freestanding = 0,
    Tosk = 1,
};

pub const Version = extern struct {
    major: u16,
    minor: u16,
    revision: u16,
    build: u16,

    pub fn eql(a: Version, b: Version) bool {
        return @as(u64, @bitCast(a)) == @as(u64, @bitCast(b));
    }
};

pub const Abi = enum(u16) {
    Msx64 = 1,
    SysV = 2,
};

pub const Tool  = extern struct {
    name_offset: u32,
    version: Version,
};

pub const Link = packed struct {
    platform: Platform,
    abi: Abi,
    platform_version: Version,
    file_version: Version,
    ofmt_version: Version,
    oem_info: u32,
    desc_offset: u32,
    tools_count: u32,
    tools_offset: u32,
};

pub const Section = packed struct {
    name_offset: u32,
    access: Access,
    chars: Characteristics,
    kind: Kind,
    /// File section alignment shift 
    physical_shift: u8, // lb(8) = 3 -> (1 << 3) = 8
    /// Image section alignment
    virtual_shift: u8,
    physical_size: u32,
    virtual_size: u32,
    pub const Access = packed struct(u8) {
        read: bool = false,
        write: bool = false,
        execute: bool = false,
        _pad: u5 = 0,

        pub fn full(s: Access) bool {
            return s.read and s.write and s.execute;
        }
        pub fn dangerous(s: Access) bool {
            // executable+writable is always a red flag
            return s.execute and s.write;
        }
    };

    pub const Characteristics = packed struct(u8) {
        discarded: bool = false,  // loader skips it entirely
        shared: bool = false,
        paged: bool = false,
        cached: bool = false,
        resource: bool = false,   // .rodata-like
        _pad: u3 = 0,

        pub fn isDangerous(c: Characteristics, a: Access) bool {
            // resource sections must never be writable or executable
            return c.resource and (a.write or a.execute);
        }
    };

    pub const Kind = enum(u8) {
        Pure = 0,
        Init = 1,     // constructor code/data
        Runtime = 2,  // loaded first, before entry
        Deinit = 3,   // destructor code/data
        Debug = 4,    // not mapped at runtime
        Signature = 5,// Must be present in Drivers 
    };
};

pub const Export = packed struct {
    name_offset: u32, // can be NULL
    target_ptr: u32,
    target_kind: ExportType,
};

pub const ExportType = enum(u8) {
    Code = 0,
    Data = 1,
};

pub const Import = packed struct {
    module_name_offset: u32,
    target_name_offset: u32,
    target_ordinal: u16,
    target_ptr: u32, // RVA where the resolved address is written???
    binding: ImportBinding,
};

pub const ImportBinding = enum(u8) {
    Lazy = 0,       // resolve on first use (via PLT-like stub)
    Runtime = 1,    // resolve at load time
    Weak = 2,       // missing symbol is not an error
};

test "Size table dec" {
    // const testing = @import("std").testing;
    const debug = @import("std").debug;
    debug.print("\nDecimal sizes\n", .{});
    debug.print("FILE           {} bytes\r\n", .{@sizeOf(File)});
    debug.print("LOAD(32|64)    {}|{} bytes\r\n", .{@sizeOf(Load32), @sizeOf(Load64)});
    debug.print("RUNTIME(32|64) {}|{} bytes\r\n", .{@sizeOf(Runtime32), @sizeOf(Runtime64)});
    debug.print("SECTION        {} bytes\r\n", .{@sizeOf(Section)});
    debug.print("EXPORT         {} bytes\r\n", .{@sizeOf(Export)});
    debug.print("IMPORT         {} bytes\r\n", .{@sizeOf(Import)});
    // FILE           24 bytes
    // LOAD(32|64)    28|56 bytes
    // RUNTIME(32|64) 16|32 bytes
    // SECTION        32 bytes
    // EXPORT         16 bytes
    // IMPORT         16 bytes
}
test "Size table hex" {
    const debug = @import("std").debug;
    debug.print("\nHexadecimal sizes\n", .{});
    debug.print("FILE          0x{X} bytes\r\n", .{@sizeOf(File)});
    debug.print("LOAD(32|64)   0x{X}|0x{X} bytes\r\n", .{@sizeOf(Load32), @sizeOf(Load64)});
    debug.print("RUNTIME(32|64)0x{X}|0x{X} bytes\r\n", .{@sizeOf(Runtime32), @sizeOf(Runtime64)});
    debug.print("SECTION       0x{X} bytes\r\n", .{@sizeOf(Section)});
    debug.print("EXPORT        0x{X} bytes\r\n", .{@sizeOf(Export)});
    debug.print("IMPORT        0x{X} bytes\r\n", .{@sizeOf(Import)});
}