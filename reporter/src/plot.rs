//! Helper type/routines for generating plots.

use chrono::{DateTime, Duration, Local, NaiveDateTime};
use plotters::prelude::*;
use plotters::style::{FontDesc, FontFamily};
use std::{collections::HashMap, ops::Range, path::PathBuf};

pub struct Point {
    /// The X-value.
    x: DateTime<Local>,
    /// The Y-value.
    y: f64,
    /// The error bar for the Y-value.
    y_err: (f64, f64),
}

impl Point {
    pub fn new(x: DateTime<Local>, y: f64, y_err: (f64, f64)) -> Self {
        Self { x, y, y_err }
    }
}

/// The data for a line on a plot.
pub struct Line {
    points: Vec<Point>,
    colour: RGBColor,
}

impl Line {
    pub fn new(colour: RGBColor) -> Self {
        Self {
            points: Vec::new(),
            colour,
        }
    }

    /// Add a point to the line.
    pub fn push(&mut self, point: Point) {
        self.points.push(point);
    }
}

#[derive(Default)]
pub struct PlotConfig {
    /// The title of the plott.
    title: String,
    /// The label to put on the x-axis.
    x_axis_label: String,
    /// The label to put on the y-axis.
    y_axis_label: String,
    /// The lines to plot. The key is the name you want on the legend.
    lines: HashMap<String, Line>,
    /// The path to write the plot into.
    output_path: PathBuf,
}

impl PlotConfig {
    pub fn new(
        title: &str,
        x_axis_label: &str,
        y_axis_label: &str,
        lines: HashMap<String, Line>,
        output_path: PathBuf,
    ) -> Self {
        Self {
            title: title.into(),
            x_axis_label: x_axis_label.into(),
            y_axis_label: y_axis_label.into(),
            lines,
            output_path,
        }
    }

    pub fn output_filename(&self) -> PathBuf {
        PathBuf::from(self.output_path.file_name().unwrap())
    }
}

/// Find appropriate min/max values for the X and Y axis.
fn find_plot_extents(lines: &HashMap<String, Line>) -> (Range<DateTime<Local>>, Range<f64>) {
    let mut start_x = NaiveDateTime::MAX.and_local_timezone(Local).unwrap();
    let mut end_x = NaiveDateTime::MIN.and_local_timezone(Local).unwrap();
    let mut start_y = f64::MAX;
    let mut end_y = f64::MIN;

    for line in lines.values() {
        for x in line.points.iter().map(|p| p.x) {
            if x <= start_x {
                start_x = x;
            }
            if x >= end_x {
                end_x = x;
            }
        }
        for yerr in line.points.iter().map(|p| p.y_err) {
            if yerr.0 <= start_y {
                start_y = yerr.0;
            }
            if yerr.1 >= end_y {
                end_y = yerr.1;
            }
        }
    }

    // Ensure we aren't butted up against the axis.
    start_x -= Duration::hours(2);
    end_x += Duration::hours(2);
    start_y -= start_y * 0.1;
    end_y += end_y * 0.1;

    assert!(start_x <= end_x);
    assert!(start_y <= end_y);
    assert!(start_x != NaiveDateTime::MIN.and_local_timezone(Local).unwrap());
    assert!(end_x != NaiveDateTime::MAX.and_local_timezone(Local).unwrap());
    (start_x..end_x, start_y..end_y)
}

/// Plot some data into a SVG file.
///
/// If we are plotting more than one line, then they are assumed to contain the same x-values.
///
/// Returns the last (rightmost) X value.
pub fn plot(config: &PlotConfig) -> DateTime<Local> {
    let (x_extent, y_extent) = find_plot_extents(&config.lines);

    let drawing = BitMapBackend::new(&config.output_path, (850, 600)).into_drawing_area();
    drawing.fill(&WHITE).unwrap();

    let mut chart = ChartBuilder::on(&drawing)
        .caption(&config.title, ("sans-serif", 20))
        .set_label_area_size(LabelAreaPosition::Left, 50)
        .set_label_area_size(LabelAreaPosition::Bottom, 50)
        .x_label_area_size(40)
        .y_label_area_size(70)
        .margin(20)
        .build_cartesian_2d(x_extent, y_extent)
        .unwrap();

    // Make axis labels easier to read.
    let desc_style =
        FontDesc::new(FontFamily::SansSerif, 18.0, "Regular".into()).into_text_style(&drawing);

    chart
        .configure_mesh()
        .x_desc(&config.x_axis_label)
        .y_desc(&config.y_axis_label)
        .axis_desc_style(desc_style)
        .x_label_formatter(&|x| x.format("%Y-%m-%d").to_string())
        .draw()
        .unwrap();

    let mut last_x = None;
    for (vm, line) in &config.lines {
        let colour = line.colour;
        // Sort the points so that the line doesn't zig-zag back and forth across the X-axis.
        let mut sorted_points = line.points.iter().map(|p| (p.x, p.y)).collect::<Vec<_>>();
        sorted_points.sort_by(|p1, p2| p1.0.partial_cmp(&p2.0).unwrap());

        // Cache the rightmost X value.
        if last_x.is_none() {
            last_x = Some(sorted_points.last().unwrap().0);
        }

        // Draw line.
        chart
            .draw_series(LineSeries::new(sorted_points, colour))
            .unwrap()
            .label(vm)
            .legend(move |(x, y)| PathElement::new(vec![(x, y), (x + 20, y)], colour));
        // Draw error bars.
        chart
            .draw_series(
                line.points
                    .iter()
                    .map(|p| ErrorBar::new_vertical(p.x, p.y_err.0, p.y, p.y_err.1, colour, 6)),
            )
            .unwrap();
    }

    // Draw on the legend.
    chart
        .configure_series_labels()
        .border_style(BLACK)
        .background_style(WHITE.mix(0.8))
        .draw()
        .unwrap();

    drawing.present().unwrap();

    last_x.unwrap()
}
