use crossterm::{
    cursor::MoveTo,
    execute,
    style::{Color, Print, ResetColor, SetBackgroundColor, SetForegroundColor, Stylize},
    terminal::{Clear, ClearType},
};
use std::io::{stdout, Result};

fn main() -> Result<()> {
    let mut stdout = stdout();

    // Clear the terminal
    execute!(stdout, Clear(ClearType::All))?;

    // Title
    execute!(
        stdout,
        MoveTo(2, 1),
        SetForegroundColor(Color::Cyan),
        Print("=== Rust Terminal Rendering: Basic Colors ==="),
        ResetColor
    )?;

    // Basic colors
    execute!(stdout, MoveTo(2, 3), Print("Basic Foreground Colors:"))?;
    let colors = [
        (Color::Red, "Red"),
        (Color::Green, "Green"),
        (Color::Blue, "Blue"),
        (Color::Yellow, "Yellow"),
        (Color::Magenta, "Magenta"),
        (Color::Cyan, "Cyan"),
        (Color::White, "White"),
    ];

    for (i, (color, name)) in colors.iter().enumerate() {
        execute!(
            stdout,
            MoveTo(4, 4 + i as u16),
            SetForegroundColor(*color),
            Print(format!("● {} text", name)),
            ResetColor
        )?;
    }

    // Background colors
    execute!(stdout, MoveTo(2, 12), Print("Background Colors:"))?;
    for (i, (color, name)) in colors.iter().enumerate() {
        execute!(
            stdout,
            MoveTo(4, 13 + i as u16),
            SetBackgroundColor(*color),
            SetForegroundColor(Color::Black),
            Print(format!(" {} ", name)),
            ResetColor
        )?;
    }

    // Styled text using the Stylize trait
    execute!(stdout, MoveTo(2, 21), Print("Text Styling:"))?;
    execute!(
        stdout,
        MoveTo(4, 22),
        Print("Bold text".bold()),
        ResetColor
    )?;
    execute!(
        stdout,
        MoveTo(4, 23),
        Print("Italic text".italic()),
        ResetColor
    )?;
    execute!(
        stdout,
        MoveTo(4, 24),
        Print("Underlined text".underlined()),
        ResetColor
    )?;
    execute!(
        stdout,
        MoveTo(4, 25),
        Print("Reversed colors".reverse()),
        ResetColor
    )?;

    // Cursor positioning demo
    execute!(stdout, MoveTo(2, 27), Print("Cursor Positioning:"))?;
    execute!(
        stdout,
        MoveTo(4, 28),
        Print("Text can be positioned "),
        SetForegroundColor(Color::Green),
        Print("anywhere"),
        ResetColor,
        Print(" on the screen!")
    )?;

    // Box drawing
    execute!(stdout, MoveTo(2, 30), Print("Box Drawing:"))?;
    draw_box(&mut stdout, 4, 31, 30, 5)?;
    execute!(
        stdout,
        MoveTo(6, 33),
        SetForegroundColor(Color::Yellow),
        Print("Content inside a box!"),
        ResetColor
    )?;

    execute!(stdout, MoveTo(0, 37), Print("\nPress Enter to exit..."))?;

    let mut input = String::new();
    std::io::stdin().read_line(&mut input)?;

    Ok(())
}

fn draw_box(stdout: &mut std::io::Stdout, x: u16, y: u16, width: u16, height: u16) -> Result<()> {
    // Top border
    execute!(stdout, MoveTo(x, y), Print("┌"))?;
    for _ in 0..width - 2 {
        execute!(stdout, Print("─"))?;
    }
    execute!(stdout, Print("┐"))?;

    // Sides
    for i in 1..height - 1 {
        execute!(stdout, MoveTo(x, y + i), Print("│"))?;
        execute!(stdout, MoveTo(x + width - 1, y + i), Print("│"))?;
    }

    // Bottom border
    execute!(stdout, MoveTo(x, y + height - 1), Print("└"))?;
    for _ in 0..width - 2 {
        execute!(stdout, Print("─"))?;
    }
    execute!(stdout, Print("┘"))?;

    Ok(())
}
