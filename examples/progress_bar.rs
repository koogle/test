use crossterm::{
    cursor::{Hide, MoveTo, Show},
    execute,
    style::{Color, Print, ResetColor, SetBackgroundColor, SetForegroundColor},
    terminal::{Clear, ClearType},
};
use std::io::{stdout, Result};
use std::thread;
use std::time::Duration;

struct ProgressBar {
    current: usize,
    total: usize,
    width: usize,
    label: String,
}

impl ProgressBar {
    fn new(total: usize, width: usize, label: String) -> Self {
        ProgressBar {
            current: 0,
            total,
            width,
            label,
        }
    }

    fn update(&mut self, current: usize) {
        self.current = current;
    }

    fn render(&self, x: u16, y: u16) -> Result<()> {
        let mut stdout = stdout();

        // Label
        execute!(
            stdout,
            MoveTo(x, y),
            SetForegroundColor(Color::White),
            Print(&self.label),
            ResetColor
        )?;

        // Calculate progress
        let percentage = (self.current as f64 / self.total as f64 * 100.0) as usize;
        let filled = (self.current as f64 / self.total as f64 * self.width as f64) as usize;

        // Progress bar
        execute!(stdout, MoveTo(x, y + 1), Print("["))?;

        // Filled portion
        execute!(
            stdout,
            SetBackgroundColor(Color::Green),
            SetForegroundColor(Color::Green)
        )?;
        for _ in 0..filled {
            execute!(stdout, Print("█"))?;
        }

        // Empty portion
        execute!(
            stdout,
            ResetColor,
            SetForegroundColor(Color::DarkGrey)
        )?;
        for _ in filled..self.width {
            execute!(stdout, Print("░"))?;
        }

        execute!(stdout, ResetColor, Print("]"))?;

        // Percentage
        execute!(
            stdout,
            Print(format!(" {}%", percentage)),
            SetForegroundColor(Color::Cyan),
            Print(format!(" ({}/{})", self.current, self.total)),
            ResetColor
        )?;

        Ok(())
    }
}

fn main() -> Result<()> {
    let mut stdout = stdout();

    // Clear screen and hide cursor
    execute!(stdout, Clear(ClearType::All), Hide)?;

    // Title
    execute!(
        stdout,
        MoveTo(2, 1),
        SetForegroundColor(Color::Cyan),
        Print("=== Progress Bar Demo ==="),
        ResetColor
    )?;

    // Create multiple progress bars
    let mut bar1 = ProgressBar::new(100, 40, "Downloading files...".to_string());
    let mut bar2 = ProgressBar::new(50, 40, "Processing data...".to_string());
    let mut bar3 = ProgressBar::new(75, 40, "Building project...".to_string());

    // Simulate progress
    for i in 0..=100 {
        // Update bars at different rates
        bar1.update(i);
        bar2.update(i / 2);
        bar3.update((i * 3) / 4);

        // Render all bars
        bar1.render(2, 3)?;
        bar2.render(2, 7)?;
        bar3.render(2, 11)?;

        // Status message
        execute!(
            stdout,
            MoveTo(2, 15),
            SetForegroundColor(Color::Yellow),
            Print(format!("Overall progress: {}%  ", i)),
            ResetColor
        )?;

        thread::sleep(Duration::from_millis(50));
    }

    // Completion message
    execute!(stdout, MoveTo(2, 17))?;
    execute!(
        stdout,
        SetForegroundColor(Color::Green),
        Print("✓ All tasks completed!"),
        ResetColor
    )?;

    // Spinner demo
    execute!(stdout, MoveTo(2, 19), Print("Spinner animation:"))?;
    let spinner_frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

    for _ in 0..3 {
        for frame in &spinner_frames {
            execute!(
                stdout,
                MoveTo(2, 20),
                SetForegroundColor(Color::Cyan),
                Print(format!("{} Loading...", frame)),
                ResetColor
            )?;
            thread::sleep(Duration::from_millis(80));
        }
    }

    execute!(
        stdout,
        MoveTo(2, 20),
        SetForegroundColor(Color::Green),
        Print("✓ Done!        "),
        ResetColor
    )?;

    execute!(stdout, MoveTo(0, 22), Show, Print("\nPress Enter to exit..."))?;

    let mut input = String::new();
    std::io::stdin().read_line(&mut input)?;

    Ok(())
}
