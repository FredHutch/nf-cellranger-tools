#!/usr/bin/env python3

import logging
from pathlib import Path
from typing import Dict
import pandas

logger = logging.getLogger(__name__)


def read_custom() -> Dict[str, str]:
    """Read the sequences from custom/"""

    return {
        header: seq
        for file in Path("custom").rglob("*")
        for header, seq in parse_fasta(file)
    }


def format_fasta(recs: Dict[str, str]):
    return "\n".join([
        f">{header}\n{seq}"
        for header, seq in recs.items()
    ])


def format_gtf(recs: Dict[str, str]):
    return "\n".join([
        format_gtf_line(header, seq)
        for header, seq in recs.items()
    ])


def format_gtf_line(header, seq):
    return "\t".join([
        header,
        "unknown", 
        "exon",
        1,
        len(seq),
        ".",
        "+",
        "."
        f'gene_id "{header}"; transcript_id "{header}"; gene_name "{header}"; gene_biotype "protein_coding"'
    ])


def parse_fasta(file: Path):

    if not file.exists():
        logger.info(f"File does not exist: {file}")
        return

    logger.info(f"Reading FASTA records from {file}")

    header = None
    seq = []

    with open(file, "r") as handle:
        for line in handle:
            if line[0] == ">":
                if header is not None and len(seq) > 0:
                    yield header, "".join(seq)
                    logger.info(f"Read {header} ({len(''.join(seq)):,}bp)")
                header = line[1:].split(" ")[0].rstrip("\n")
                seq = []
            else:
                if len(line) > 1:
                    seq.append(line.rstrip("\n"))

    if header is not None and len(seq) > 0:
        yield header, "".join(seq)    
        logger.info(f"Read {header} ({len(''.join(seq)):,}bp)")


def append(file_in, file_out, footer):
    with open(file_in, "r") as handle_in:
        with open(file_out, "w") as handle_out:
            handle_out.write(handle_in.read())
            handle_out.write(footer)


def main():
    custom = read_custom()

    append(
        "input.fasta",
        "merged.fasta",
        format_fasta(custom)
    )

    append(
        "input.gtf",
        "merged.gtf",
        format_gtf(custom)
    )


if __name__ == "__main__":
    main()