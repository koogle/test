use crossterm::{
    cursor::{Hide, MoveTo, Show},
    event::{self, Event, KeyCode, KeyEvent},
    execute,
    style::{Color, Print, ResetColor, SetBackgroundColor, SetForegroundColor},
    terminal::{self, Clear, ClearType, EnterAlternateScreen, LeaveAlternateScreen},
};
use std::io::{stdout, Result};

struct MenuItem {
    label: String,
    description: String,
}

struct Menu {
    items: Vec<MenuItem>,
    selected: usize,
}

impl Menu {
    fn new(items: Vec<MenuItem>) -> Self {
        Menu { items, selected: 0 }
    }

    fn next(&mut self) {
        self.selected = (self.selected + 1) % self.items.len();
    }

    fn previous(&mut self) {
        if self.selected == 0 {
            self.selected = self.items.len() - 1;
        } else {
            self.selected -= 1;
        }
    }

    fn render(&self) -> Result<()> {
        let mut stdout = stdout();
        execute!(stdout, Clear(ClearType::All))?;

        // Title
        execute!(
            stdout,
            MoveTo(2, 1),
            SetForegroundColor(Color::Cyan),
            Print("╔════════════════════════════════════════╗"),
            ResetColor
        )?;
        execute!(
            stdout,
            MoveTo(2, 2),
            SetForegroundColor(Color::Cyan),
            Print("║    Interactive Menu - Use ↑↓ & Enter ║"),
            ResetColor
        )?;
        execute!(
            stdout,
            MoveTo(2, 3),
            SetForegroundColor(Color::Cyan),
            Print("╚════════════════════════════════════════╝"),
            ResetColor
        )?;

        // Menu items
        for (i, item) in self.items.iter().enumerate() {
            let y = 5 + (i * 3) as u16;

            if i == self.selected {
                // Highlighted item
                execute!(
                    stdout,
                    MoveTo(2, y),
                    SetBackgroundColor(Color::Green),
                    SetForegroundColor(Color::Black),
                    Print(format!(" ▶ {} ", item.label)),
                    ResetColor
                )?;
                execute!(
                    stdout,
                    MoveTo(4, y + 1),
                    SetForegroundColor(Color::DarkGrey),
                    Print(format!("   {}", item.description)),
                    ResetColor
                )?;
            } else {
                // Normal item
                execute!(
                    stdout,
                    MoveTo(2, y),
                    SetForegroundColor(Color::White),
                    Print(format!("   {} ", item.label)),
                    ResetColor
                )?;
                execute!(
                    stdout,
                    MoveTo(4, y + 1),
                    SetForegroundColor(Color::DarkGrey),
                    Print(format!("   {}", item.description)),
                    ResetColor
                )?;
            }
        }

        // Instructions
        let instructions_y = 5 + (self.items.len() * 3) as u16 + 2;
        execute!(
            stdout,
            MoveTo(2, instructions_y),
            SetForegroundColor(Color::Yellow),
            Print("Press ↑/↓ to navigate, Enter to select, 'q' to quit"),
            ResetColor
        )?;

        Ok(())
    }
}

fn main() -> Result<()> {
    // Setup terminal
    let mut stdout = stdout();
    terminal::enable_raw_mode()?;
    execute!(stdout, EnterAlternateScreen, Hide)?;

    let menu = Menu::new(vec![
        MenuItem {
            label: "Start Application".to_string(),
            description: "Launch the main application".to_string(),
        },
        MenuItem {
            label: "Settings".to_string(),
            description: "Configure application settings".to_string(),
        },
        MenuItem {
            label: "View Logs".to_string(),
            description: "Display system logs".to_string(),
        },
        MenuItem {
            label: "Help".to_string(),
            description: "Show help documentation".to_string(),
        },
        MenuItem {
            label: "Exit".to_string(),
            description: "Close the application".to_string(),
        },
    ]);

    let result = run_menu(menu);

    // Cleanup
    execute!(stdout, Show, LeaveAlternateScreen)?;
    terminal::disable_raw_mode()?;

    result
}

fn run_menu(mut menu: Menu) -> Result<()> {
    loop {
        menu.render()?;

        if let Event::Key(KeyEvent { code, .. }) = event::read()? {
            match code {
                KeyCode::Up => menu.previous(),
                KeyCode::Down => menu.next(),
                KeyCode::Enter => {
                    let mut stdout = stdout();
                    execute!(stdout, Clear(ClearType::All), MoveTo(0, 0))?;
                    execute!(
                        stdout,
                        SetForegroundColor(Color::Green),
                        Print(format!("Selected: {}\n", menu.items[menu.selected].label)),
                        ResetColor
                    )?;
                    execute!(stdout, Print("Press any key to continue..."))?;
                    event::read()?;
                }
                KeyCode::Char('q') | KeyCode::Esc => break,
                _ => {}
            }
        }
    }

    Ok(())
}
