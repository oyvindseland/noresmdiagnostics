load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$DIAG_SHARED/lnd_func.ncl"
load "$WKDIR/variable_master.ncl"
;************************************************
begin
  print ("=========================================")
  print ("Starting:  set_8_zonal.ncl; zonal tracers")
  print ("Start Time: "+systemfunc("date") )
  print ("=========================================")
  ptmpdir = getenv("PTMPDIR")
  wkdir   = getenv("WKDIR")
  useCommon1 = getenv("UseCommonName_1")


; the set lists contains two columns of information. This comes into
; NCL as one long string that we need to parse out.
  tmp = stringtocharacter(asciiread(wkdir+"/master_set8_zonal.txt",-1,"string"))
  nvar = dimsizes(tmp(:,0))
  scale_type = new(nvar,"string")
  vars       = new(nvar,"string")
  dFlag      = new(nvar,"string")
  do i=0,nvar-1
    scale_type(i) = charactertostring(tmp(i,0:12))
    vars(i)       = charactertostring(tmp(i,16:))
    dFlag(i)      = charactertostring(tmp(i,16:17))
  end do

  seasons = (/"DJF","JJA","MAM","SON","ANN"/)
;*************************************************
; main loop
;*************************************************
  
  do i=0,dimsizes(vars)-1 
    prefix   = new(1,"string")
    useFlag1 = useCommon1 
    if (useFlag1 .eq. "1") then
          name1   = "commonName_1"
    else
          name1   = "caseid_1"
    end if
    name11      = "prefix_1"
    prefix(0)      = getenv(name11)

; loop over seasons

  do n = 0,dimsizes(seasons)-1
      print("Processing season " + seasons(n))
      in1       = addfile(ptmpdir+"/"+prefix(0)+"/atm/"+prefix(0)+"_"+seasons(n)+"_climo_atm.nc","r")
      nlev1      = getfilevardimsizes(in1,"lev")
      lat1       = in1->lat
      lon1       = in1->lon
      time       = in1->time
      nlat1      = dimsizes(lat1)
      nlon1      = dimsizes(lon1)
      data = new((/1,nlat1/),"float")
      
   ; *************************
   ; read case 1 model variable
   ; *************************


     plot_check1 = True
     if (dFlag(i) .eq. "SF") then
        if(isfilevar(in1,vars(i)))then
                x = in1->$vars(i)$
        else
                if (vars(i) .eq. "SFCO2_LND") then
        	     if(isfilevar(in1,"SFCO2_LN"))then
                        x = in1->SFCO2_LN
		     end if
                end if
                if (vars(i) .eq. "SFCO2_OCN") then
        	     if(isfilevar(in1,"SFCO2_OC"))then
                        x = in1->SFCO2_OC
		     end if
                end if
                if (vars(i) .eq. "SFCO2_FFF") then
        	     if(isfilevar(in1,"SFCO2_FF"))then
                        x = in1->SFCO2_FF
		     end if
                end if
        end if
      else
        info = var_init(vars(i))
      	if(isfilevar(in1,vars(i)))then
             x   = in1->$vars(i)$
	else
             if (info@derivedVariable .eq. True) then
            	x = derive_land(  vars(i),in1)
             else
                print("variable "+ vars(i)+ " is not a defined variable.")
                plot_check1 = False
                continue
             end if
      	 end if
      end if
      if (.not.isvar("x")) then
                plot_check1 = False
      end if
      if(plot_check1.eq.False)then
	  continue
      else
      	rank       = dimsizes(dimsizes(x))
      	if(rank .eq. 4) then
	     x1  = x(:,nlev1-1,:,:)	; lev0 = top of atm 
      	else
	     x1  = x
      	end if

      	delete(x)

      	print(" " + vars(i))

      	; catch NaNs
      	x1 = catchNaN(x1)

      	info = var_init(vars(i))
      	x1   = scale_var(x1,scale_type(i),info)
      	x11  = dim_avg_Wrap(x1)

; extract years averaged for plotting
    	if (isatt(in1,"yrs_averaged")) then
        	yrs_ave1 = in1@yrs_averaged
    	end if

    	cases    = new(2,"string")
    	cases(0) = getenv(name1)
    	cases(0) = cases(0) + " (" + yrs_ave1 + ")"
    	cases(1) = "No Obs"

; calculate zonal values
    	  data(0,:) = x11
          plat = lat1
          data!0 = "line"
          data!1 = "lat"
          data&lat = plat
     
;*************************************************
; create plot
;*************************************************
        plot = new(1,graphic)

    	wks = gsn_open_wks("ps",wkdir + "set8_zonal_"+seasons(n) +"_"+vars(i))
   	 
    	pres                       = True
        pres@gsnMaximize           = True                   ; make as large as possible
        pres@gsnPaperOrientation   = "Portrait"
        pres@gsnPanelCenter        = True
        pres@gsnPanelBottom        = 0.15                   ; save space for legend
        pres@gsnPanelRowSpec       = True
        pres@gsnFrame              = False                  ; don't advance yet so add legend
        pres@txString              = seasons(n)

    	res                        = True
        res@gsnDraw                = False                  ; don't advance yet so add legend
        res@gsnFrame               = False                  ; don't advance yet so add legend
    	res@tiXAxisString          = "Latitude"
    	res@tiYAxisString          = x1@units
    	res@xyDashPatterns         = (/0.,16./)          ; solid, dashed
    	res@xyLineThicknesses      = (/2.,2./)
    	res@xyLineColors           = (/"red","blue"/)
	
    	res@pmLegendDisplayMode    = "Never"
    	res@pmLegendSide           = "Bottom"            
    	res@pmLegendParallelPosF   = 0.50           
    	res@pmLegendOrthogonalPosF = 0.02              
    	res@pmLegendWidthF         = 0.25             
    	res@pmLegendHeightF        = 0.08 
    	res@lgLabelFontHeightF     = 0.020
    	res@lgPerimOn              = True
    	res@xyExplicitLegendLabels = cases
    	res@tmXBMinorOn            = False
    	res@tiMainString           = x1@long_name

        lgres                       = True                   ; allow legend resources
        lgres@lgLineColors          = res@xyLineColors       ; set these equal to those
        lgres@lgPerimOn             = True
        lgres@lgDashIndexes         = res@xyDashPatterns     ; ditto
        lgres@lgLabelFontHeightF    = 0.040                  ; increase font height
        lgres@lgLineLabelStrings    = (/"",""/)              ; no labels in lines
        lgres@lgAutoManage          = False                  ; must have to adjust fonts
        lgres@vpWidthF              = 0.35
        lgres@vpHeightF             = 0.10

    	plot(0) = gsn_csm_xy(wks,plat,data,res)   

        gsn_panel(wks,plot,1,pres)               ; draw panel plot
        gsn_legend_ndc(wks,2,cases,0.35,0.12,lgres)    ; draw common legend    MAY HAVE TO ADJUST Y

	frame(wks)
    	delete(x1)
    	delete(x11)
    	delete(plot)
    	delete(cases)
    	delete(data)
    	delete(res)
    end if	; plot_check loop   
   end do   	; end seasons loop
  end do   	; end variable plot

  ; remove error file if program completes successfully.  
  filo  = wkdir +"/set8_zonal_error_file"                   
  system("/bin/rm -f " + filo)
  exit

end
