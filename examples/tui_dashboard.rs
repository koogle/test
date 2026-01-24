use crossterm::{
    event::{self, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{
        Bar, BarChart, BarGroup, Block, Borders, Gauge, List, ListItem, Paragraph, Sparkline,
    },
    Terminal,
};
use std::io::{self, Result};
use std::time::{Duration, Instant};

struct App {
    counter: u64,
    data: Vec<u64>,
    cpu_usage: u16,
    memory_usage: u16,
}

impl App {
    fn new() -> Self {
        App {
            counter: 0,
            data: vec![2, 5, 3, 8, 6, 7, 4, 9, 10, 8, 6, 7],
            cpu_usage: 65,
            memory_usage: 42,
        }
    }

    fn update(&mut self) {
        self.counter += 1;
        // Simulate changing data
        self.data.rotate_left(1);
        self.data[11] = (self.counter % 10) + 1;

        // Simulate CPU/Memory fluctuation
        self.cpu_usage = ((self.counter * 7) % 100) as u16;
        self.memory_usage = ((self.counter * 3) % 80) as u16;
    }
}

fn main() -> Result<()> {
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();
    let tick_rate = Duration::from_millis(250);
    let result = run_app(&mut terminal, &mut app, tick_rate);

    // Cleanup
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    if let Err(err) = result {
        println!("Error: {:?}", err);
    }

    Ok(())
}

fn run_app<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
    tick_rate: Duration,
) -> Result<()> {
    let mut last_tick = Instant::now();

    loop {
        terminal.draw(|f| {
            // Create layout
            let chunks = Layout::default()
                .direction(Direction::Vertical)
                .margin(1)
                .constraints(
                    [
                        Constraint::Length(3),
                        Constraint::Length(3),
                        Constraint::Length(10),
                        Constraint::Min(5),
                    ]
                    .as_ref(),
                )
                .split(f.area());

            // Title
            let title = Paragraph::new(vec![Line::from(vec![
                Span::styled(
                    "Rust TUI Dashboard ",
                    Style::default()
                        .fg(Color::Cyan)
                        .add_modifier(Modifier::BOLD),
                ),
                Span::styled(
                    format!("(Counter: {})", app.counter),
                    Style::default().fg(Color::Yellow),
                ),
                Span::raw("  Press 'q' to quit"),
            ])])
            .block(Block::default().borders(Borders::ALL).title("Info"));
            f.render_widget(title, chunks[0]);

            // CPU and Memory Gauges
            let gauge_chunks = Layout::default()
                .direction(Direction::Horizontal)
                .constraints([Constraint::Percentage(50), Constraint::Percentage(50)].as_ref())
                .split(chunks[1]);

            let cpu_gauge = Gauge::default()
                .block(Block::default().title("CPU Usage"))
                .gauge_style(Style::default().fg(Color::Green))
                .percent(app.cpu_usage);
            f.render_widget(cpu_gauge, gauge_chunks[0]);

            let memory_gauge = Gauge::default()
                .block(Block::default().title("Memory"))
                .gauge_style(Style::default().fg(Color::Blue))
                .percent(app.memory_usage);
            f.render_widget(memory_gauge, gauge_chunks[1]);

            // Sparkline chart
            let sparkline = Sparkline::default()
                .block(
                    Block::default()
                        .title("Activity (Sparkline)")
                        .borders(Borders::ALL),
                )
                .data(&app.data)
                .style(Style::default().fg(Color::Cyan));
            f.render_widget(sparkline, chunks[2]);

            // Split bottom section
            let bottom_chunks = Layout::default()
                .direction(Direction::Horizontal)
                .constraints([Constraint::Percentage(50), Constraint::Percentage(50)].as_ref())
                .split(chunks[3]);

            // Bar chart
            let bar_data = vec![
                ("Jan", app.data[0]),
                ("Feb", app.data[1]),
                ("Mar", app.data[2]),
                ("Apr", app.data[3]),
                ("May", app.data[4]),
                ("Jun", app.data[5]),
            ];

            let barchart = BarChart::default()
                .block(Block::default().title("Monthly Stats").borders(Borders::ALL))
                .data(
                    BarGroup::default().bars(
                        &bar_data
                            .iter()
                            .map(|(label, value)| {
                                Bar::default()
                                    .value(*value)
                                    .label(Line::from(*label))
                                    .style(Style::default().fg(Color::Yellow))
                            })
                            .collect::<Vec<_>>(),
                    ),
                )
                .bar_width(5)
                .bar_gap(1);
            f.render_widget(barchart, bottom_chunks[0]);

            // List widget
            let items: Vec<ListItem> = vec![
                "System Status: Running",
                "Active Connections: 42",
                "Uptime: 7d 3h 24m",
                "Last Update: Now",
                "Errors: 0",
                "Warnings: 2",
            ]
            .iter()
            .enumerate()
            .map(|(i, text)| {
                let style = if i % 2 == 0 {
                    Style::default().fg(Color::White)
                } else {
                    Style::default().fg(Color::Gray)
                };
                ListItem::new(*text).style(style)
            })
            .collect();

            let list = List::new(items)
                .block(Block::default().title("System Info").borders(Borders::ALL))
                .style(Style::default().fg(Color::White));
            f.render_widget(list, bottom_chunks[1]);
        })?;

        // Handle input
        let timeout = tick_rate
            .checked_sub(last_tick.elapsed())
            .unwrap_or_else(|| Duration::from_secs(0));

        if event::poll(timeout)? {
            if let Event::Key(key) = event::read()? {
                if let KeyCode::Char('q') = key.code {
                    return Ok(());
                }
            }
        }

        if last_tick.elapsed() >= tick_rate {
            app.update();
            last_tick = Instant::now();
        }
    }
}
