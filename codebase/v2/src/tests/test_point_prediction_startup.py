"""Dependency-free startup checks: python test_point_prediction_startup.py --rscript PATH."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SRC = Path(__file__).resolve().parents[1]
NOTEBOOK = json.loads((SRC / "predict_gpr_at_points.ipynb").read_text(encoding="utf-8"))
RSCRIPT = shutil.which("Rscript")


def r_string(value):
    return json.dumps(str(value))


class PointPredictionStartupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="seagrass-startup-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "kernel home"
        self.clone = self.home / "Seagrass_carbon_stock_model"
        self.root = self.clone / "codebase" / "v2" / "src"
        self.helpers = self.root / "modelling" / "R"
        self.helpers.mkdir(parents=True)
        shutil.copyfile(SRC / "modelling" / "R" / "project_root.R",
                        self.helpers / "project_root.R")
        (self.helpers / "init_repo.R").write_text(
            'seagrass_init_repo <- function(...) {\n'
            '  stop(paste0("STARTUP_OK:", getwd()), call. = FALSE)\n'
            '}\n', encoding="utf-8"
        )
        (self.root / "predict_gpr_at_points.R").write_text(
            'stopifnot(identical(Sys.getenv("SEAGRASS_V2_ROOT"), project_root))\n'
            'selected_script <- normalizePath(script_path, winslash = "/")\n',
            encoding="utf-8"
        )
        self.env = os.environ.copy()
        self.env.pop("SEAGRASS_V2_ROOT", None)

    def run_r(self, code, cwd=None):
        runner = Path(self.temp.name) / "runner.R"
        runner.write_text(code, encoding="utf-8")
        return subprocess.run(
            [RSCRIPT, "--vanilla", str(runner)],
            cwd=cwd or self.home, env=self.env, capture_output=True, text=True,
            timeout=30, check=False
        )

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def helper_code(self):
        return (
            f"sys.source({r_string(self.helpers / 'project_root.R')}, .GlobalEnv)\n"
            f"expected <- normalizePath({r_string(self.root)}, winslash = '/')\n"
        )

    def test_root_layouts_and_explicit_paths(self):
        directories = [self.root, self.root.parent, self.clone / "codebase",
                       self.clone, self.helpers, self.home]
        for directory in directories:
            with self.subTest(directory=directory):
                self.assert_success(self.run_r(
                    self.helper_code()
                    + "stopifnot(identical(seagrass_find_v2_root(), expected))\n",
                    cwd=directory
                ))
        unrelated = Path(self.temp.name) / "unrelated"
        unrelated.mkdir()
        for explicit in [self.clone, self.root.parent, self.root]:
            with self.subTest(explicit=explicit):
                self.assert_success(self.run_r(
                    self.helper_code()
                    + f"Sys.setenv(SEAGRASS_V2_ROOT = {r_string(explicit)})\n"
                    + "stopifnot(identical(seagrass_find_v2_root(), expected))\n",
                    cwd=unrelated
                ))

    def test_errors_do_not_fall_back(self):
        invalid = self.clone / "missing"
        result = self.run_r(
            self.helper_code()
            + f"seagrass_find_v2_root(project_path = {r_string(invalid)})\n"
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Invalid SEAGRASS_V2_ROOT", result.stderr)
        unrelated = Path(self.temp.name) / "unrelated"
        unrelated.mkdir()
        result = self.run_r(self.helper_code() + "seagrass_find_v2_root()\n", cwd=unrelated)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Kernel working directory:", result.stderr)
        self.assertIn("Checked:", result.stderr)
        for invalid_value in ["NA_character_", "character()", 'c("a", "b")']:
            with self.subTest(value=invalid_value):
                result = self.run_r(
                    self.helper_code()
                    + f"seagrass_find_v2_root(project_path = {invalid_value})\n"
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("single directory path", result.stderr)

    def notebook_code(self, explicit=None):
        code = "".join(NOTEBOOK["cells"][0]["source"])
        if explicit is not None:
            code = code.replace(
                'project_path <- Sys.getenv("SEAGRASS_V2_ROOT", "")',
                f"project_path <- {r_string(explicit)}"
            )
        return code

    def test_notebook_automatic_and_explicit_discovery(self):
        cases = [(directory, None) for directory in
                 [self.home, self.clone, self.root.parent, self.root]]
        unrelated = Path(self.temp.name) / "unrelated"
        unrelated.mkdir()
        cases += [(unrelated, explicit) for explicit in
                  [self.clone, self.root.parent, self.root]]
        for cwd, explicit in cases:
            with self.subTest(cwd=cwd, explicit=explicit):
                result = self.run_r(
                    self.notebook_code(explicit)
                    + f"expected <- normalizePath({r_string(self.root)}, winslash = '/')\n"
                    + "stopifnot(identical(project_root, expected),\n"
                    + "  identical(selected_script, file.path(expected, 'predict_gpr_at_points.R')),\n"
                    + "  is.na(Sys.getenv('SEAGRASS_V2_ROOT', unset = NA_character_)))\n"
                    + "".join(NOTEBOOK["cells"][1]["source"]),
                    cwd=cwd
                )
                self.assert_success(result)

    def test_notebook_override_and_environment_restoration(self):
        self.env["SEAGRASS_V2_ROOT"] = "invalid environment path"
        self.assert_success(self.run_r(
            self.notebook_code(self.clone)
            + "stopifnot(Sys.getenv('SEAGRASS_V2_ROOT') == 'invalid environment path')\n"
        ))
        (self.root / "predict_gpr_at_points.R").write_text(
            'stop("prediction failure", call. = FALSE)\n', encoding="utf-8"
        )
        self.assert_success(self.run_r(
            "error <- tryCatch({\n" + self.notebook_code(self.clone)
            + "\nNULL\n}, error = identity)\n"
            + "stopifnot(conditionMessage(error) == 'prediction failure',\n"
            + "  Sys.getenv('SEAGRASS_V2_ROOT') == 'invalid environment path')\n"
        ))

    def test_notebook_invalid_path(self):
        result = self.run_r(self.notebook_code(self.clone / "missing"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Invalid project_path:", result.stderr)
        self.assertIn("Checked:", result.stderr)
        unrelated = Path(self.temp.name) / "unrelated"
        unrelated.mkdir()
        result = self.run_r(self.notebook_code(), cwd=unrelated)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Cannot find the v2 project root.", result.stderr)
        self.assertIn("Kernel working directory:", result.stderr)

    def test_notebook_environment_configuration(self):
        unrelated = Path(self.temp.name) / "unrelated"
        unrelated.mkdir()
        self.env["SEAGRASS_V2_ROOT"] = str(self.clone)
        self.assert_success(self.run_r(
            self.notebook_code()
            + f"stopifnot(Sys.getenv('SEAGRASS_V2_ROOT') == {r_string(self.clone)})\n",
            cwd=unrelated
        ))

    def test_source_and_rscript_startup_outside_clone(self):
        shutil.copyfile(SRC / "predict_gpr_at_points.R",
                        self.root / "predict_gpr_at_points.R")
        unrelated = Path(self.temp.name) / "unrelated"
        unrelated.mkdir()
        result = self.run_r(
            f"source({r_string(self.root / 'predict_gpr_at_points.R')})\n",
            cwd=unrelated
        )
        self.assertIn("STARTUP_OK:" + self.root.as_posix(), result.stderr)
        result = self.run_r("source('predict_gpr_at_points.R')\n", cwd=self.root)
        self.assertIn("STARTUP_OK:" + self.root.as_posix(), result.stderr)
        result = self.run_r(self.notebook_code(), cwd=self.home)
        self.assertIn("STARTUP_OK:" + self.root.as_posix(), result.stderr)
        result = subprocess.run(
            [RSCRIPT, "--vanilla", str(self.root / "predict_gpr_at_points.R")],
            cwd=unrelated, env=self.env, capture_output=True, text=True,
            timeout=30, check=False
        )
        self.assertIn("STARTUP_OK:" + self.root.as_posix(), result.stderr)
        result = subprocess.run(
            [RSCRIPT, "--vanilla", "predict_gpr_at_points.R"],
            cwd=self.root, env=self.env, capture_output=True, text=True,
            timeout=30, check=False
        )
        self.assertIn("STARTUP_OK:" + self.root.as_posix(), result.stderr)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rscript", default=RSCRIPT)
    args, remaining = parser.parse_known_args()
    RSCRIPT = args.rscript
    if not RSCRIPT:
        parser.error("Rscript is not on PATH; supply --rscript with the installed executable.")
    unittest.main(argv=[__file__, *remaining])
