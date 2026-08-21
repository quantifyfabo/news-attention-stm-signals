# news-attention-stm-signals
For the replication of the working paper 'Extracting Time-Lagged Signals from Unstructured News Articles: A Structural Topic Modeling Approach'

# Replication Material & Online Appendix

This repository contains all the code, scripts, and datasets required for a full replication of the models and statistics. 

### Repository Overview & Instructions

* **Scripts & Languages:** The repository includes all R files (provided as both `.qmd` and `.R` formats) as well as the Python files used to query the New York Times (NYT) API, as described in the methods section. 
* **Order:** To ensure fully identical results, the code must be executed in the given numerical order. However, because the corresponding datasets are loaded at the beginning of each script, you can easily start with any specific file (e.g., the Results script) as long as the required data is present. 
* **Reproducibility:** A defined seed has been set for all procedural models, such as the Structural Topic Model (STM), to guarantee identical outputs. 
* **Dependencies & Setup:** Before running the scripts, please ensure that all used packages are installed (if necessary, run `install.packages("packagename")` manually). You may also need to adjust your working directory and file paths to correctly point to the downloaded datasets.
* **HTML Previews:** To simplify the review process, the two core files (`MT_03_Models` and `MT_04_Results`) are provided as `.qmd` files containing brief explanations of each methodological step. I have also rendered these files into **HTML format**. This allows you to view the entire code and its corresponding outputs directly in your browser without needing to run the code in R yourself.
* **Thesis Outputs:** All figures, plots, and statistical results presented in the Master's thesis are based entirely on this code and data.

**Overall, the simplest way to understand the code and instantly see the results is to download and open the rendered HTML versions of `MT_03_Models` and `MT_04_Results`.**

- Fabian Gienke
