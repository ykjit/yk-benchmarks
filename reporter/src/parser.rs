//! Rebench results file parser.

use std::{
    collections::HashMap,
    fs::File,
    io::{self, BufRead, BufReader},
    path::Path,
};

#[derive(Debug)]
pub struct ResultsFile {
    /// Maps a field name to its column index.
    col_map: HashMap<String, usize>,
    /// Rows of data.
    rows: Vec<Vec<String>>,
}

impl ResultsFile {
    pub fn row(&self, idx: usize) -> &Vec<String> {
        &self.rows[idx]
    }

    pub fn len(&self) -> usize {
        self.rows.len()
    }

    pub fn col_idx(&self, col: &str) -> usize {
        self.col_map[col]
    }
}

fn split_by_tab(line: &str) -> Vec<String> {
    line.split("\t").map(|v| v.to_owned()).collect::<Vec<_>>()
}

/// Parse the results for the given benchmark (using the given argument) from the specified on-disk
/// results file.
pub fn parse(res_file: &Path, bm_name: &str, bm_arg: &str) -> Result<ResultsFile, io::Error> {
    let f = BufReader::new(File::open(res_file)?);
    let mut col_map = None;
    let mut rows = Vec::new();
    let mut bm_name_idx = None;
    let mut bm_arg_idx = None;

    for line in f.lines() {
        let line = line?;
        if line.starts_with("#") {
            continue;
        }
        if col_map.is_none() {
            let col_names = split_by_tab(&line);
            let mut map = HashMap::new();
            for (idx, name) in col_names.iter().enumerate() {
                map.insert(name.to_owned(), idx);
                if name == "benchmark" {
                    bm_name_idx = Some(idx);
                }
                if name == "extraArgs" {
                    bm_arg_idx = Some(idx);
                }
            }
            col_map = Some(map);
        } else {
            let row = split_by_tab(&line);
            if row[bm_name_idx.unwrap()] == bm_name && row[bm_arg_idx.unwrap()] == bm_arg {
                rows.push(split_by_tab(&line));
            }
        }
    }
    if rows.is_empty() {
        panic!("parsed zero rows from results file! Mis-spelled becnhmark name?");
    }
    Ok(ResultsFile {
        col_map: col_map.unwrap(),
        rows,
    })
}
