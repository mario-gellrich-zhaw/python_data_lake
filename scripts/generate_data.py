"""Generate synthetic sales data as a single raw CSV file.

This simulates the "raw landing zone" of a data lake: one wide, uncompressed
CSV file, exactly as it would arrive from a source system (ERP export, POS
system, etc.) before any curation happens.

Usage:
    python scripts/generate_data.py
    python scripts/generate_data.py --rows 500000 --out lake/raw/sales.csv
"""

from __future__ import annotations

import argparse
import time
from pathlib import Path

import numpy as np
import pandas as pd

REGIONS = [
    "Zurich", "Bern", "Basel", "Geneva", "Lucerne",
    "Winterthur", "St. Gallen", "Lausanne",
]

PRODUCTS = [
    "Laptop 14in", "Laptop 16in", "Wireless Mouse", "Mechanical Keyboard",
    "USB-C Dock", "27in Monitor", "Webcam HD", "Noise Cancelling Headset",
    "Office Chair", "Standing Desk", "Desk Lamp", "External SSD 1TB",
    "External SSD 2TB", "Router", "Network Switch", "Label Printer",
    "Barcode Scanner", "Tablet 10in", "Smartphone Case", "Power Bank",
]

DEFAULT_ROWS = 300_000
DEFAULT_START = "2024-01-01"
DEFAULT_END = "2026-08-24"
CHUNK_SIZE = 100_000


def generate_chunk(
    n: int, start_ts: pd.Timestamp, total_days: int, rng: np.random.Generator
) -> pd.DataFrame:
    offsets = rng.integers(0, total_days + 1, size=n)
    dates = start_ts + pd.to_timedelta(offsets, unit="D")

    quantity = rng.integers(1, 20, size=n)
    unit_price = rng.uniform(15.0, 1200.0, size=n).round(2)
    noise = rng.normal(1.0, 0.05, size=n)
    revenue = (quantity * unit_price * noise).round(2)

    return pd.DataFrame(
        {
            "date": dates.strftime("%Y-%m-%d"),
            "region": rng.choice(REGIONS, size=n),
            "product": rng.choice(PRODUCTS, size=n),
            "quantity": quantity,
            "revenue": revenue,
        }
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rows", type=int, default=DEFAULT_ROWS)
    parser.add_argument("--out", type=str, default="lake/raw/sales.csv")
    parser.add_argument("--start", type=str, default=DEFAULT_START)
    parser.add_argument("--end", type=str, default=DEFAULT_END)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    start_ts = pd.Timestamp(args.start)
    total_days = (pd.Timestamp(args.end) - start_ts).days
    rng = np.random.default_rng(args.seed)

    t0 = time.time()
    rows_written = 0
    first_chunk = True

    while rows_written < args.rows:
        n = min(CHUNK_SIZE, args.rows - rows_written)
        chunk = generate_chunk(n, start_ts, total_days, rng)
        chunk.to_csv(
            out_path,
            mode="w" if first_chunk else "a",
            header=first_chunk,
            index=False,
        )
        first_chunk = False
        rows_written += n
        print(f"  {rows_written:>10,} / {args.rows:,} rows written")

    elapsed = time.time() - t0
    size_mb = out_path.stat().st_size / (1024 * 1024)
    print(f"\nDone in {elapsed:.1f}s")
    print(f"File:  {out_path}")
    print(f"Size:  {size_mb:.1f} MB")
    print(f"Rows:  {rows_written:,}")


if __name__ == "__main__":
    main()
