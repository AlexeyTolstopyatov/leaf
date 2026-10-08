//
// CoffeeLake(c) 2026-*
// 
// @machine: atvlg
// @creator: atolstopyatov20178@vk.com
// 
//! This file contains public API of given module... 
//!
//! The "Little-Enchanted" Application Format
//! Experimental object module format for 64-bit Tosk OS executable objects
//! 
//! Program header is a START structure which describe minimal information about
//! application. 
//!  * comptime info always placed in `_link` section.
//!  * runtime info placed in the `_load`.
//! 
//! The top field of `_load` module section contains CPU byte ordering test
//!  * If `magic` value not LEAF -> test failed -> module not loadable
//! 
//! The type of module defined by file system extension
//!     long       8.3         type
//!  * .leaf     (.lea)     executable
//!  * .stickl   (.skl)     static linked library
//!  * .stickd   (.skd)     dynamic linked library
//!  * .root     (.roo)     kernel extension/driver
//! 
//! The check value must be not null. This is a magic value
//! which always compares with an image data at the run-time. 
//!  * If check failed -> module not loadable 
//!
//! LEAF images are have linear address space, because of the modern concept
//! to virtualize all memory what the loader have. Same with PE/COFF executables,
//! the LEAF linked images are have special `Load::base` pointer which tells a loader
//! an image start location. 
//!
const leaf = @import("leaf.zig");

pub const Load = leaf.Load;
pub const Link = leaf.Link;
pub const Section = leaf.Section;
pub const Tool = leaf.Tool;
pub const Module = leaf.Module;
pub const Platform = leaf.Platform;
pub const Version = leaf.Version;
pub const Export = leaf.Export;