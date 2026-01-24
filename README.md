# # Rust Terminal Rendering Exploration

This project explores different approaches to rendering content in the terminal using Rust. It demonstrates everything from basic color output to full-featured Terminal User Interfaces (TUIs).

## Overview

Terminal rendering in Rust is primarily achieved through two popular libraries:

1. **crossterm** - A cross-platform terminal manipulation library that provides low-level control over:
   - Colors and text styling
   - Cursor positioning
   - Keyboard and mouse input
   - Terminal mode control (raw mode, alternate screen)

2. **ratatui** - A high-level TUI framework (successor to tui-rs) that provides:
   - Layout management
   - Built-in widgets (charts, gauges, lists, tables, etc.)
   - Event handling
   - Efficient rendering

## Examples

### 1. Basic Colors (`basic_colors.rs`)
Demonstrates fundamental terminal manipulation:
- Foreground and background colors
- Text styling (bold, italic, underline, reverse)
- Cursor positioning
- Box drawing with Unicode characters

```bash
cargo run --example basic_colors
```

**Key Concepts:**
- Using `execute!` macro for command execution
- Color enums and styling
- Coordinate-based text positioning
- Unicode box-drawing characters

### 2. Interactive Menu (`interactive_menu.rs`)
A keyboard-driven interactive menu system:
- Arrow key navigation
- Visual selection feedback
- Raw mode input handling
- Alternate screen buffer

```bash
cargo run --example interactive_menu
```

**Key Concepts:**
- Terminal raw mode for capturing individual keystrokes
- Event loop pattern for interactive applications
- Alternate screen (preserves terminal history)
- Stateful UI rendering

### 3. Progress Bars (`progress_bar.rs`)
Real-time progress visualization:
- Multiple concurrent progress bars
- Percentage and count display
- Animated spinner
- Dynamic updates without flicker

```bash
cargo run --example progress_bar
```

**Key Concepts:**
- Real-time terminal updates
- Progress calculation and visualization
- Spinner animation frames
- Coordinated multi-widget rendering

### 4. TUI Dashboard (`tui_dashboard.rs`)
Full-featured terminal dashboard using ratatui:
- Complex layouts with multiple widgets
- Bar charts and sparklines
- Gauges for metrics
- Live updating data
- Professional-looking UI

```bash
cargo run --example tui_dashboard
```

**Key Concepts:**
- Ratatui's layout system
- Widget composition
- Event-driven updates
- State management in TUI apps

## Building and Running

```bash
# Run the main program (shows overview)
cargo run

# Run a specific example
cargo run --example <example_name>

# Build all examples
cargo build --examples
```

## Architecture Patterns

### Low-Level (crossterm)
```rust
use crossterm::{execute, cursor::MoveTo, style::Print};
let mut stdout = stdout();
execute!(stdout, MoveTo(10, 5), Print("Hello!"))?;
```

**Pros:**
- Direct control over terminal
- Minimal dependencies
- Good for simple CLIs

**Cons:**
- Manual layout management
- More boilerplate code
- No built-in widgets

### High-Level (ratatui)
```rust
use ratatui::{widgets::Paragraph, Frame};
fn ui(frame: &mut Frame) {
    let paragraph = Paragraph::new("Hello!");
    frame.render_widget(paragraph, frame.area());
}
```

**Pros:**
- Rich widget library
- Automatic layout
- Cleaner code for complex UIs

**Cons:**
- Steeper learning curve
- Larger dependency tree

## Common Use Cases

- **CLI Tools**: Progress bars, menus, confirmations
- **System Monitors**: CPU/memory dashboards, log viewers
- **Development Tools**: Build status, test runners
- **Games**: Roguelikes, text adventures
- **Data Visualization**: Charts, graphs in the terminal

## Key Takeaways

1. **crossterm** is excellent for adding colors and simple interactive elements to CLI tools
2. **ratatui** shines for complex, widget-based terminal applications
3. Both libraries are cross-platform (Windows, macOS, Linux)
4. Raw mode is essential for interactive applications
5. Alternate screen preserves user's terminal session
6. Event-driven architecture works well for TUIs

## Resources

- [crossterm documentation](https://docs.rs/crossterm/)
- [ratatui documentation](https://docs.rs/ratatui/)
- [Ratatui examples](https://github.com/ratatui-org/ratatui/tree/main/examples)

## Next Steps

Try modifying the examples to:
- Add mouse support to the interactive menu
- Create a file browser TUI
- Build a system resource monitor
- Make a terminal-based game
- Add real-time data feeds to the dashboard
