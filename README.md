# MSc-Thesis-Portfolio
MSc Thesis code: Panel ARDL econometric analysis of FDI impact on economic growth in Latin America (University of Leeds).

# Econometric Analysis: FDI & Economic Growth in Latin America

### Project Overview
This repository contains the source code and econometric scripts developed for my MSc in Economics and Finance thesis at the **University of Leeds** (2024-2025).

The study investigates the impact of **Foreign Direct Investment (FDI)** on the economic growth of Latin American countries. Using a **Panel ARDL (Auto-Regressive Distributed Lag)** approach, the model analyzes long-run and short-run relationships, assessing cointegration among macroeconomic variables.

### Methodology & Tech Stack
* **Methodology:** Panel ARDL / Mean Group (MG), Pooled Mean Group (PMG) Estimators. 
* **Tests Performed:** Correlation, Unit Root Tests (IPS/ADF/Perron/CIPS/CADF), Cointegration Tests (Pedroni/Kao/Westerlund), Multicollinearity Test (VIF), Hausman Test.
* **Language/Software:** Stata 17. 
* **Key Libraries/Commands:** `xtpmg`, `xtdcce2`.

### Repository Structure
Since the dataset contains proprietary/restricted information, **raw data files are not included** in this repository. The file **`Master_Script.do`** contains the full workflow, organized into the following sections:

0. **SETUP**.
1. **Correlation Analysis**.
2. **Panel Unit Root Tests:** Checking stationarity (IPS, ADF, PP).
3. **Cross-sectional Dependence (CIPS, CADF)**.
4. **Cointegration Tests:** Checking for I(1) variables.
5. **Variance Inflation Factor (VIF):** Test for Multicollinearity.
6. **Panel ARDL estimation:** Execution of MG and PMG Estimators.
7. **Post-estimation:** Diagnostic tests and tables.
8. **Robustness:** Outlier Detection.

### Data Disclaimer
**Note:** The dataset used for this analysis includes data from World Bank / IMF / UNCTAD / UNDP. Due to privacy and copyright restrictions, the source data files are not published here. The code is provided for demonstration of technical and econometric skills only.

### Author
**Raúl Moreno Aguilera**
* **MSc Economics & Finance** (Distinction) - University of Leeds
* **BSc in Business Administration** - Universidad Mayor
* [LinkedIn Profile](https://www.linkedin.com/in/raul-moreno-aguilera/)
