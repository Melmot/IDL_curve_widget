; To add: mode and axis switches

pro draw_curve_event, event
;	help, event, /str, widget_info(event.id,/uname)
	case widget_info(event.id,/uname) of
		'canvas': draw_curve_track, event
		'zoom_in': draw_curve_zoom, event.top, /in
		'zoom_out': draw_curve_zoom, event.top, /out
		'clear': draw_curve_clear, event.top
		'done': widget_control, event.top, /destroy
   	else:
	endcase
end



pro draw_curve_cleanup, mainwin
	widget_control, mainwin, get_uvalue=data, /no_copy
	*data.result = {x:*data.points.x, y:*data.points.y}
	if keyword_set(data) then heap_free, data.points, /ptr
end



function draw_curve, image, x=x, y=y, full=full
	if not keyword_set(image) then image = bytarr(200,200);rebin(bindgen(16,16),256,256);
	if keyword_set(y) then ax='y' else ax='x'
	if keyword_set(full) then full=1b else full=0b

	dims = size(image, /dim)
	zoom = 1.
	result_ptr = ptr_new(/allocate_heap)

	curve_x = ptr_new(0)
	curve_y = ptr_new(0)
	if full then if ax eq 'x' then *curve_x = findgen(dims[0]) else *curve_y = findgen(dims[1])

	data = {image:image, dims:dims, zoom:zoom, result:result_ptr, $
			points:{x:ptr_new(), y:ptr_new(), n:0, move:-1}, $
			curve:{x:curve_x, y:curve_y, ax:ax, full:full} }

	mainwin = widget_base(title='DRAW CURVE', mbar=mainwin_mbar, /col)
	canvas = widget_draw(mainwin, xsize=dims[0]*zoom, ysize=dims[1]*zoom, uname='canvas', /motion, /button, /scroll, frame=0)
	controls = widget_base(mainwin, /row, /base_align_left, space=2, uname='controls')
	test_btn = widget_button(controls, value='-', uname='zoom_out', /align_center, sensitive=0)
	test_btn = widget_button(controls, value='+', uname='zoom_in', /align_center, sensitive=1)
	test_btn = widget_button(controls, value='Clear', uname='clear', /align_center, sensitive=1)
	test_btn = widget_button(controls, value='OK', uname='done', /align_center, sensitive=1)

	winsize = widget_info(mainwin,/geometry)
	scrsize = get_screen_size()
	widget_control, mainwin, /realize, set_uvalue=data, /no_copy, $ xoffs=-7, yoffs=0
		xoffs=(scrsize[0]-winsize.xsize)/2, yoffs=(scrsize[1]-winsize.ysize)/2-50, /delay_destroy
	draw_curve_draw, mainwin
	xmanager, 'draw_curve', mainwin, /no_block, cleanup='draw_curve_cleanup', /modal		; /modal means that execution is halted here until widget is destroyed

	result = {x:*curve_x, y:*curve_y} ;, points:*result_ptr
	ptr_free, result_ptr, curve_x, curve_y
	return, result
end



pro draw_curve_draw, mainwin
	widget_control, mainwin, get_uvalue=data
	widget_control, widget_info(mainwin, find_by_uname='canvas'), get_value=win_id
	wset, win_id
	tv, rebin(data.image, data.dims*data.zoom, /sample)

	if data.points.n gt 0 then begin
		plot, *data.points.x, *data.points.y, /noerase, ps=4, syms=0.3, thick=2*(0.5+data.zoom)<8, $ , syms=0.2*(0.5+data.zoom)<0.3
			xr=[0,data.dims[0]-1], yr=[0,data.dims[1]-1], xst=5, yst=5, pos=[0,0,1,1]

		if data.points.n ge 3 then begin
			if not data.curve.full then begin
				if data.curve.ax eq 'x' then begin
					x1 = min(*data.points.x, max=x2)
					*data.curve.x = findgen(x2-x1+1)+x1
				endif else begin
					y1 = min(*data.points.y, max=y2)
					*data.curve.y = findgen(y2-y1+1)+y1
				endelse
			endif
			if data.curve.ax eq 'x' then *data.curve.y = spline(*data.points.x, *data.points.y, *data.curve.x) $
									else *data.curve.x = spline(*data.points.y, *data.points.x, *data.curve.y)
			oplot, *data.curve.x, *data.curve.y, thick=0.75*(0.5+data.zoom)<3
			widget_control, mainwin, set_uvalue=data, /no_copy
		endif
	endif
end



pro draw_curve_track, event
	widget_control, event.top, get_uvalue=data
	if (event.press ne 1) and (event.release ne 1) and (data.points.move eq -1) and (event.press ne 4) then return
	cur = {x:event.x/data.zoom, y:event.y/data.zoom}

	if event.press eq 1 then begin
		if data.points.n gt 0 then begin
			dist = (*data.points.x-cur.x)^2 + (*data.points.y-cur.y)^2
			min_dist = min(dist, min_ind)
			if min_dist le 3*data.zoom then data.points.move = min_ind
		endif
		if data.points.move eq -1 then begin
			if data.points.n eq 0 then begin
				data.points.n = 1
				data.points.x = ptr_new(cur.x)
				data.points.y = ptr_new(cur.y)
				data.points.move = 0
			endif else begin
				data.points.n+= 1
				*data.points.x = [*data.points.x, cur.x]
				*data.points.y = [*data.points.y, cur.y]
				if data.curve.ax eq 'x' then sort_ind = sort(*data.points.x) else sort_ind = sort(*data.points.y)
				*data.points.x = (*data.points.x)[sort_ind]
				*data.points.y = (*data.points.y)[sort_ind]
				data.points.move = (where(sort_ind eq data.points.n-1))[0]
			endelse
		endif
	endif

	if event.release eq 1 then data.points.move = -1

	if data.points.move ne -1 then begin
		(*data.points.x)[data.points.move] = cur.x
		(*data.points.y)[data.points.move] = cur.y
		if data.curve.ax eq 'x' then sort_ind = sort(*data.points.x) else sort_ind = sort(*data.points.y)
		*data.points.x = (*data.points.x)[sort_ind]
		*data.points.y = (*data.points.y)[sort_ind]

;		widget_control, event.top, set_uvalue=data, /no_copy
;		draw_curve_draw, event.top
;		return
	endif

	if event.press eq 4 then begin
		if data.points.n gt 0 then begin
			dist = (*data.points.x-cur.x)^2 + (*data.points.y-cur.y)^2
			min_dist = min(dist, min_ind)
			if min_dist le 3/data.zoom then begin
				leave_ind = where(dist ne dist[min_ind])
				if leave_ind eq [-1] then begin
					data.points.n = 0
					ptr_free, data.points.x, data.points.y
				endif else begin
					data.points.n-= 1
					*data.points.x = (*data.points.x)[leave_ind]
					*data.points.y = (*data.points.y)[leave_ind]
				endelse
			endif
		endif
	endif

	widget_control, event.top, set_uvalue=data, /no_copy
	draw_curve_draw, event.top
end



pro draw_curve_zoom, mainwin, in=in, out=out
	widget_control, mainwin, get_uvalue=data

	if keyword_set(in) then begin
		data.zoom*= 2
		widget_control, widget_info(mainwin, find_by_uname='zoom_out'), sensitive=1
	endif

	if keyword_set(out) then begin
		if data.zoom eq 2 then widget_control, widget_info(mainwin, find_by_uname='zoom_out'), sensitive=0
		data.zoom/= 2
	endif

	canvsd_id = widget_info(mainwin, find_by_uname='canvas')
	cansize = widget_info(canvsd_id, /geometry)
	winsize = widget_info(mainwin, /geometry)
	scrsize = get_screen_size()
	maxcanv = [scrsize[0] - winsize.xsize + cansize.xsize, scrsize[1] - winsize.ysize + cansize.ysize] - [50,100]

	widget_control, canvsd_id, draw_xsize=data.dims[0]*data.zoom, draw_ysize=data.dims[1]*data.zoom, $
		xsize=data.dims[0]*data.zoom < maxcanv[0], ysize=data.dims[1]*data.zoom <  maxcanv[1]
	widget_control, mainwin, set_uvalue=data, /no_copy
	winsize = widget_info(mainwin, /geometry)
	widget_control, mainwin, xoffs=(scrsize[0]-winsize.xsize)/2, yoffs=(scrsize[1]-winsize.ysize)/2-50
	draw_curve_draw, mainwin
end



pro draw_curve_clear, mainwin
	widget_control, mainwin, get_uvalue=data

	data.points.n = 0
	ptr_free, data.points.x, data.points.y
	data.points.move = -1

	widget_control, mainwin, set_uvalue=data, /no_copy
	draw_curve_draw, mainwin
end