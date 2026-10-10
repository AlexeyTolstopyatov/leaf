# The LEAF Object Format Experiment

The `LEAF` is a shorten form of "Little-Enchanted" Application Format, the experimental
object module format designed for [Тоска](https://github.com/AlexeyTolstopyatov/tosk) 
operating system. 

The main idea of given project - to recompile all knowledge base about Windows NT 
runtime mechanics and _produce_ platform-independent container, which not includes 
rich operating system features if it doesn't need at all.

## Contents
 - [LEAF File Layout](#leaf-file-layout)
 - [Why Not PE?](#why-not-portable-executable)
 - [Why Not ELF?](#why-not-executablelinkable-format)

## LEAF File Layout

The LEAF OFMT presents two main structures for various user targets.
The `LOAD(+FILE)` and `LINK` header sections. So, the all necessary image information
which needs to be resolved at the load-time/run-time presented in the `LOAD` structure
And all user data needed for reverse engineering or deep analytics presented in the `LINK`
section.

```
┌────────────────────────┐
│ FILE header section  │
├────────────────────────┤
│ LOAD header section  │
├────────────────────────┤
│ LINK header section  │
│ and LINK strings     │
├────────────────────────┤
│   SECTION TABLE      │
│ RELOCACTION BLOCKS   │
├────────────────────────┤
│ 00 01 FF 4D D6 90 20 │
│ 33 00 00 03 00 04 FF │
│ 56 09 DA F0 0B CC 3C │
├────────────────────────┤
│ 03 00 05 DD 0A 5F 4D │
├────────────────────────┤
│  .export section     │
├────────────────────────┤
|  .import section     │
├────────────────────────┤
├────────────────────────┤
│ ???                  │ Under construction
└────────────────────────┘
```

## What does the loader need?

At the moment of 1.0.1(.16) revision the solution about loader was the next.
The loader must know 
 - The program image location;
 - Addresses what loader is need to fix-up (or relocate);
 - Maximum machine word size;
 - Address of the entry point;
 - Section table details;

To know more see [leaf.zig](src/leaf.zig).

## What does linker tell?

Linker section tells more details about executable image, for example
 - Internal Module name
 - Registered operating system integer
 - ABI integer tag
 - Operating system version
 - File version
 - OFMT version
 - OEM info (optional)
 - Module description
 - Toolchain count (optional)
 - Toolchain array (optional)

Fields without `(optional)` are mandatory and fills by the lead linker 
(in this repository). Using a special `link.zig.zon` instead of command line infernal interface
you can describe it all for a successful module linkage.

## Why not Portable Executable?

I know about Microsoft/IBM little more than about Unix world.
That is why I have far more arguments against this format, and they are significantly more weighty.

Portable Executable object module format was designed as an opposite of
IBM/Microsoft OS/2 executable files (i.e. Linear Executables).
Since Windows NT 3x and Windows 95, the per-segment relocations and segmented executable
model was marked as deprecated. So Windows NT 3x, Windows 9x are use linear addressing space
in the 32-bit mode and applications no more uses the callgate mechanics to provide IO privileges.

PE (or MSCOFF) format was a continuous development of Unix COFF and unfortunately
was increased and maximum Windows NT adopted. Those solutions you can see if you look little deeper
into abandoned Microsoft frameworks and technologies 
(e.g. Windows CE PE ROMs, Microsoft Multimedia Operating System Architecture, and more)

Wrong information deeply embedded into every object/module is a first argument to make an experiment

For example, the subsystem flags was permanently declared by many toolkits, and misinformation was populated.
Because of `Subsystem` flag number 8 is not a `Windows Native` marker. This is a Win32e subsystem
flag which was a part of MMOSA. The undocumented `IMAGE_OPTIONAL_ROM_HEADER` still stays
in Microsoft Rust crates! The `LoaderFlags` and `Win32Value` fields are empty and deprecated.
The false target of `Win32Value` is still around us in the official docs.
The unused COFF `FILE_HEADER` linenumbers and debug values uses only for object files, not
dynamically linked modules.

Second argument to make an experiment is a strange fields location which Microsoft was made.
Many fields of `IMAGE_OPTIONAL_HEADER` are unused since Windows NT 4.x but not replaced!
Memory allocator takes whole 224 bytes instead of necessary 32 bytes and 
relocates huge process structures. This is not optimal solution for a poor student. 

## Why not Executable/Linkable Format?

Good question. The ELF object module format was developed by many years and become
an icon of embedded systems. Many of Unix-like operating systems already use it.
But many legacy code and unused features are stays in the ELF. 
For example the physical addresses of every segment are unused in the modern OSes
So extremely needed details might be skipped during the linking stage 
(unknown ABI flag or always-togged-SystemV-ABI flag).

Being honest, the ELF format is a main format which inspire me to make an experiment
because of lightweight loader modules (for a freestanding ELF64 bin-s.) and 
`.comment`, `.ctor/dtor` sections instead of Visual Studio embeddings.
