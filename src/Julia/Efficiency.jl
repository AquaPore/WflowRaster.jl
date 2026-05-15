# =============================================================
#		module: efficiency
# =============================================================
module efficiency

	using Statistics

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : KLING_GUPTA_EFFICIENCY
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	"""
	Modified Kling-Gupta efficiency (KGE) metric for evaluating the performance of hydrological models. The KGE metric is a comprehensive measure that combines three components: correlation, bias, and variability. It provides a more balanced assessment of model performance compared to traditional metrics like Nash-Sutcliffe Efficiency (NSE).

		g, H., Fuchs, M., Paulin, M., 2012. Runoff conditions in the upper Danube basin under an ensemble of climate change scenarios. J. Hydrol. 424–425, 264–277. https://doi.org/10.1016/j.jhydrol.2012.01.011
	"""
	function KLING_GUPTA_EFFICIENCY(;Qobs, Qsim)
      Qobs_𝝁 = Statistics.mean((Qobs))
      Qsim_𝝁 = Statistics.mean(Qsim)
      Qobs_𝝈 = Statistics.std(Qobs)
      Qsim_𝝈 = Statistics.std(Qsim)

		# Calculate the components of KGE
      r  = Statistics.cor((Qobs), (Qsim))  #  Pearson correlation between the vectors or matrices
      β  = Qsim_𝝁 / Qobs_𝝁  # Bias ratio
      𝝀 = (Qsim_𝝈 / Qsim_𝝁) / (Qobs_𝝈 / Qobs_𝝁)  # Variability ratio

		# Calculate KGE using the formula
		Kge = 1.0 - √ ((r - 1.0)^2 + (β - 1.0)^2 + (𝝀 - 1.0)^2)

		Kge = floor(Kge, digits=3)
	return Kge
	end  # function: KLING_GUPTA_EFFICIENCY
	# ------------------------------------------------------------------

end  # module: efficiency
# ............................................................