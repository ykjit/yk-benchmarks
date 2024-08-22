use chrono::{Local, NaiveDateTime};
use plotters::prelude::*;
use reporter::{
    parser::parse,
    plot::{plot, Line, PlotConfig, Point},
};
use std::{collections::HashMap, io::Write, path::PathBuf};
use walkdir::{DirEntry, WalkDir};

/// Benchmarks to plot.
const BENCHES_TO_PLOT: [(&str, &str); 14] = [
    ("DeltaBlue", "12000"),
    ("Richards", "100"),
    ("Json", "100"),
    ("CD", "250"),
    ("Havlak", "1500"),
    ("Bounce", "1500"),
    ("List", "1500"),
    ("Mandelbrot", "500"),
    ("NBody", "250000"),
    ("Permute", "1000"),
    ("Queens", "1000"),
    ("Sieve", "3000"),
    ("Storage", "1000"),
    ("Towers", "600"),
];

/// Colours of the lines on the plots.
const LINE_COLOURS: [(&str, RGBColor); 3] = [("Lua", BLUE), ("YkLua", RED), ("Norm", MAGENTA)];

fn process_file(
    entry: &DirEntry,
    bm_name: &str,
    bm_arg: &str,
    abs_lines: &mut HashMap<String, Line>,
    norm_line: &mut Line,
    line_colours: &HashMap<&str, RGBColor>,
) {
    // Parse the results file filtering out the benchmark of interest.
    let rf = parse(entry.path(), bm_name, bm_arg).unwrap();
    // Collect execution times on a per-vm basis.
    let mut exec_times: HashMap<String, Vec<f64>> = HashMap::new();
    for row_idx in 0..rf.len() {
        let row = rf.row(row_idx);
        debug_assert!(row[rf.col_idx("benchmark")] == bm_name);
        debug_assert!(row[rf.col_idx("extraArgs")] == bm_arg);
        let vm_name = &row[rf.col_idx("executor")];

        debug_assert!(row[rf.col_idx("unit")] == "ms");
        let time = row[rf.col_idx("value")].parse::<f64>().unwrap().round();
        exec_times
            .entry(vm_name.to_string())
            .or_default()
            .push(time as f64);
    }
    // Get the X value by parsing the date in the filename.
    let filename = entry.path().file_name().unwrap().to_str().unwrap();
    let xval = NaiveDateTime::parse_from_str(filename, "%Y%m%d_%H%M%S.data")
        .unwrap()
        .and_local_timezone(Local)
        .unwrap();
    // Compute points for the absolute times plot.
    for (vm, exec_times) in &exec_times {
        let yval = exec_times.iter().sum::<f64>() / (exec_times.len() as f64);
        let line = abs_lines
            .entry(vm.to_string())
            .or_insert(Line::new(line_colours[vm.as_str()]));
        let y_err = (
            *exec_times
                .iter()
                .min_by(|a, b| a.partial_cmp(b).unwrap())
                .unwrap(),
            *exec_times
                .iter()
                .max_by(|a, b| a.partial_cmp(b).unwrap())
                .unwrap(),
        );
        line.push(Point::new(xval, yval, y_err));
    }
    // Compute Y values for the normalised plot.
    let norm_extimes = &exec_times["Lua"]
        .iter()
        .zip(&exec_times["YkLua"])
        .map(|(lua, yklua)| lua / yklua)
        .collect::<Vec<_>>();
    let yval = norm_extimes.iter().sum::<f64>() / (norm_extimes.len() as f64);
    norm_line.push(Point::new(
        xval,
        yval,
        (
            *norm_extimes
                .iter()
                .min_by(|a, b| a.partial_cmp(b).unwrap())
                .unwrap(),
            *norm_extimes
                .iter()
                .max_by(|a, b| a.partial_cmp(b).unwrap())
                .unwrap(),
        ),
    ));
}

fn write_html_header(html: &mut std::fs::File) -> Result<(), std::io::Error> {
    use std::io::Write;
    writeln!(html, "<html><head>")?;
    writeln!(html, "<title>Yk Benchmarking Results</title>")?;
    writeln!(html, "<h1>Yk Benchmarking Results</h1>")?;
    writeln!(
        html,
        "Generated: {}",
        Local::now().format("%Y-%m-%d %H:%M:%S")
    )?;
    Ok(())
}

fn write_html_footer(html: &mut std::fs::File) -> Result<(), std::io::Error> {
    writeln!(html, "</head></html>")?;
    Ok(())
}

fn usage() -> ! {
    println!("usage: reporter <results-dir> <output-html-dir>");
    std::process::exit(1)
}

fn main() {
    let mut args = std::env::args().skip(1);
    let res_dir = args.next().unwrap_or_else(|| usage());
    let html_dir = args.next().unwrap_or_else(|| usage());

    // Create the output dir and HTML file.
    let out_dir = PathBuf::from(html_dir);
    if !out_dir.exists() {
        std::fs::create_dir(&out_dir).unwrap();
    }
    let mut html_fn = out_dir.clone();
    html_fn.push("index.html");
    let mut html = std::fs::File::create(html_fn).unwrap();
    write_html_header(&mut html).unwrap();

    // Process one benchmark at a time so that we don't hold a lot of data in memory at once.
    let line_colours = HashMap::from(LINE_COLOURS);
    for (bm_name, bm_arg) in BENCHES_TO_PLOT {
        let mut abs_lines = HashMap::new();
        let mut norm_line = Line::new(line_colours["Norm"]);
        // Search for data files.
        let walker = WalkDir::new(&res_dir).into_iter();
        for entry in walker {
            let entry = entry.unwrap();
            if !entry.file_type().is_file() {
                continue;
            }
            process_file(
                &entry,
                bm_name,
                bm_arg,
                &mut abs_lines,
                &mut norm_line,
                &line_colours,
            );
        }

        write!(html, "<h2>{bm_name}({bm_arg})</h2>").unwrap();

        // Plot aboslute times.
        let mut output_path = out_dir.clone();
        output_path.push(format!("{bm_name}_{bm_arg}_vs_yklua.svg"));
        let config = PlotConfig::new(
            "Benchmark performance over time",
            "Date",
            "Wallclock time (ms) with error (min/max)",
            abs_lines,
            output_path,
        );
        plot(&config);
        write!(
            html,
            "<img align='center' src='{}' />",
            config.output_filename().to_str().unwrap()
        )
        .unwrap();

        // Plot data normalised to yklua.
        let mut output_path = out_dir.clone();
        output_path.push(format!("{bm_name}_{bm_arg}_norm_yklua.svg"));
        let config = PlotConfig::new(
            "Benchmark performance over time, normalised to regular Lua",
            "Date",
            "Speedup with error (min/max)",
            HashMap::from([("Norm".into(), norm_line)]),
            output_path,
        );
        plot(&config);
        write!(
            html,
            "<img align='center' src='{}' />",
            config.output_filename().to_str().unwrap()
        )
        .unwrap();
    }
    write_html_footer(&mut html).unwrap();
}
