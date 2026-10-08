//
// CoffeeLake(c) 2026-*
// 
// @machine: atvlg
// @creator: atolstopyatov20178@vk.com
// 
///
/// `_load` section is a definitely start of every executable/loadable image
/// This is a minimal image payload which loader needs to resolve at the runtime 
/// 
/// Every `_offset` field tells that entity location is a raw file offset.
/// Every `_ptr` field tells that offset is a relative and depends on image `base`
/// 
/// __This rule uses everywhere same with Hungarian notation `a` and `p` prefixes__
///
pub const Load = packed struct {
    magic: u32, // place ASCII bytes as a default integer
    cpu: Architecture, // 16
    /// Maximum machine word available. Depending on it, the relocation table size
    /// and export/import addresses are declared. 
    /// No more magic tricks with image characteristics!
    cpu_word: u8, // 8
    module: Module, // u8
    base: u32,
    sections_offset: u32,
    sections_count: u32,
    relocs_offset: u32,
    relocs_count: u32,
    entry_ptr: u32,
    
    pub const MAGIC_LE: u32 = 0x4C454146;
    pub const MAGIC_BE: u32 = 0x4641454C;
    pub const LEAF_VERSION: Version = .{
        .major = 1,
        .minor = 0,
        .revision = 1,
        .build = 16 // zig??
    };
    
    pub fn test_magic(m: u32) bool {
        return m == MAGIC_BE or m == MAGIC_LE;
    }
    pub fn test_ofmt(m: Version) bool {
        return Version.eql(m, LEAF_VERSION);
    }
};
/// 
/// Architecture enum defines registered CPU architectures
/// for program images
/// 
pub const Architecture = enum(u16) {
    None = 0,
    IA32 = 1,
    IA32e = 2,
    ARM = 3,
    ARM64 = 4,
    ARM7 = 5,
    // ...
};
/// 
/// Same with Microsoft concept, Module definition flags are presented
/// a program specific which loader must to resolve at the runtime
/// 
/// Despite the Microsoft/IBM specific this field is mandatory for Tosk programs,
/// then reverse engineering process of given images will be little simpler
///
pub const Module = enum(u8) {
    Discarded = 0,
    Executable = 1,
    Library = 2,
    Driver = 3,
};
/// 
/// Registered Operating systems are placed here.
/// 
pub const Platform = enum(u16) {
    /// This is not `NotSpecified` or `Any` word, this word a special flag
    /// for a decompiling process, that image can't store any runtime/operating system specific 
    Freestanding = 0,
    /// Some Tosk executables (e.g. console.roo) are marked as Tosk executables/drivers, not freestanding
    /// because of `console.roo` image belong to Tosk ~eco~system concept, so loader `_load` section
    /// already defines image behaviour.
    ///
    /// Anyway the `init.lea` are marked as freestanding because it starts the Tosk concept 
    /// and loads first from EFI boot services/custom boot loader
    Tosk = 2,
};

pub const Version = packed struct {
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
    SysV = 2, // *
};

pub const Tool = extern struct {
    name_offset: u32, // ASCIIZ string
    version: Version  // u64
};
/// 
/// Link section defines rich object module information
/// necessary data of Link section is internal module name
/// because of symbols resolving at run-time.  
/// 
pub const Link = packed struct {
    name_offset: u32,          // internal module name (uses by module runtime?)
    platform: Platform,        // Operating System name-tag
    abi: Abi,                  // Registered ABI tag used in the image
    platform_version: Version, // operating system version
    file_version: Version,     // file image version
    ofmt_version: Version,     // object format version
    oem_info: u32,             // the OEM/LD last words
    desc_offset: u32,          // module description (optional)
    tools_count: u32,          // tool count (optional)
    tools_offset: u32,         // tool list (default=0)
    
    pub const FAT_EXEC: []const u8 = ".LEA";
    pub const FAT_DLIB: []const u8 = ".SKD";
    pub const FAT_SLIB: []const u8 = ".SKL";
    pub const FAT_SDRV: []const u8 = ".ROO";
    
    pub const LONG_EXEC: []const u8 = ".LEAF";
    pub const LONG_DLIB: []const u8 = ".STICK.D";
    pub const LONG_SLIB: []const u8 = ".STICK.S";
    pub const LONG_SDRV: []const u8 = ".ROOT";
};

pub const Section = extern struct {
    name_offset: u32,
    access: u8, // Bitmask of Access
    chars: u8,  // Bitmask of Characteristic
    kind: u8,
    start_offset: u32,
    physical_size: u32,
    virtual_size: u32,
    
    pub const Access = enum(u8) {
        Read      = 0b00000001,
        Write     = 0b00000010,
        Execute   = 0b00000100,
    };
    pub const Kind = enum(u8) {
        /// Constructor section flag, same with .ctor uses 
        /// to store initialization prologues or data 
        Init = 0b00000001,
        /// Destructor section flag.
        Deinit = 0b10000000,
        
        /// If section contains marked as pure code or data, loader resolves it as loader "wants" 
        pub fn isPure(kind: u8) bool {
            const init = @intFromEnum(Kind.Init);
            const deinit = @intFromEnum(Kind.Deinit);
            
            return ((kind & init) == 0) and ((kind & deinit) == 0);
        }
    };
    pub const Characteristics = enum(u8) {
        Discarded = 0b00000010,
        Shared    = 0b00000100,
        Paged     = 0b00001000,
        Cached    = 0b00010000,
        Resource  = 0b01000000,
    };
    pub fn hasFullAcess(s: u8) bool {
        return (s & (Access.Execute | Access.Read | Access.Write) != 0);
    }
    pub fn isInit(s: u8) bool {
        return (s & Characteristics.Init) != 0;
    }
    pub fn isDeinit(s: u8) bool {
        return (s & Characteristics.DeInit) != 0;
    }
    pub fn isUnloadable(s: u8) bool {
        return (s & Characteristics.Discarded) != 0;
    }
    pub fn isDangerous(a: u8, s: u8) bool {
        // Resource sections never executable anymore.
        // Writable resources might be a strange changing payload?
        return ((a & Access.Execute) or (a & Access.Write)) and (s & Characteristics.Resource); 
    }
};

///   
/// Export structure defines the whole module API.
/// Same with the New and Linear executables format 
/// 
pub const Export = packed struct {
    // If address set to null, the exporting procedure/data structure 
    // calls by ordinal number. Same with MS/IBM project solution... 
    name_offset: u32,
    // gate_selector: u16
    section_pointer: u32 // linear address
    
};

test "pointers and sizes" {
    const testing = @import("std").debug;
    
    const load_layout = comptime @sizeOf(Load);
    
    testing.print("_load=0x{X}|0x{X}\r\n", .{@sizeOf(Load), load_layout});
    testing.print("_link=0x{X}\r\n", .{@sizeOf(Link)});
    testing.print("_section=0x{X}\r\n", .{@sizeOf(Section)});
}