function compute_rho(p:numeric,t:numeric,s:numeric)
begin

; Define constants
  a11= 9.9985372432159340e+02
  a12= 1.0380621928183473e+01
  a13= 1.7073577195684715e+00
  a14=-3.6570490496333680e-02
  a15=-7.3677944503527477e-03
  a16=-3.5529175999643348e-03
  a21= 1.0
  a22= 1.0316374535350838e-02
  a23= 8.9521792365142522e-04
  a24=-2.8438341552142710e-05
  a25=-1.1887778959461776e-05
  a26=-4.0163964812921489e-06
  b11= 1.7083494994335439e-02
  b12= 7.1567921402953455e-05
  b13= 1.2821026080049485e-05
  b21= 1.1995545126831476e-05
  b22= 5.5234008384648383e-08
  b23= 8.4310335919950873e-09

; Compute rho
  rho_nom=a11+t*(a12+a14*t+a15*s)+s*(a13+a16*s)+p*(b11+b12*t+b13*s)
  rho_denom=a21+t*(a22+a24*t+a25*s)+s*(a23+a26*s)+p*(b21+b22*t+b23*s)
  rho=t ; copy metadata
  rho=rho_nom/rho_denom
  rho@long_name = "density"
  rho@units = "kg/m3"
  assignFillValue(rho,rho)
  delete(rho_nom)
  delete(rho_denom)
  return rho
end
