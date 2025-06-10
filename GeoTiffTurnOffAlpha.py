import os
import tempfile
from osgeo import gdal

gdal.UseExceptions()  # Optional but helps with error reporting

def fix_alpha_flag_inplace(file_path: str):
    """Fix a GeoTIFF file in-place by disabling alpha interpretation on 4-band NAIP imagery."""
    try:
        # Open dataset
        src_ds = gdal.Open(file_path)
        if src_ds is None:
            print(f"Skipping: could not open {file_path}")
            return
        # Only proceed if the file has exactly 4 bands
        if src_ds.RasterCount != 4:
            print(f"Skipping: {file_path} has {src_ds.RasterCount} bands (not 4)")
            return
        # Create temporary output file in same directory
        dir_name = os.path.dirname(file_path)
        with tempfile.NamedTemporaryFile(suffix=".tif", dir=dir_name, delete=False) as tmpfile:
            temp_path = tmpfile.name
        # Translate to new file with ALPHA turned off
        gdal.Translate(
            temp_path,
            src_ds,
            bandList=[1, 2, 3, 4],
            creationOptions=["ALPHA=NO"]
        )
        # Close dataset explicitly
        src_ds = None
        del src_ds
        # Replace original file
        os.replace(temp_path, file_path)
        print(f"Fixed: {os.path.basename(file_path)}")

    except Exception as e:
        print(f"Error processing {file_path}: {e}")

def process_directory(folder_path: str):
    """Run alpha-fix in-place on all GeoTIFF files in a directory."""
    for filename in os.listdir(folder_path):
        if filename.lower().endswith(".tif"):
            full_path = os.path.join(folder_path, filename)
            fix_alpha_flag_inplace(full_path)

# Update this path to point to folder:
directory = r"N:\\Research\\Ogle\Agroforestry\\phase1_nebraska\\data\\products\\twoMileSubGridEvaluations\\selectedSubGrids\\NAIP"
process_directory(directory)
