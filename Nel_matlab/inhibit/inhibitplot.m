% Script to create gain vs freq plot for srcal%pushbuttons switch control to test, simulate, tuning_curve and analyses functionsh_push_start    = uicontrol(h_fig,'callback','inhibit_curve(''start'');','style','pushbutton','Units','normalized', ...   'position',[.625 .18 .25 .062],'string','Push to begin','Userdata',[],'fontsize',14,'fontangle','normal', ...   'fontweight','normal');h_push_params  = uicontrol(h_fig,'callback','inhibit_curve(''params'');','style','pushbutton','Units','normalized', ...   'position',[.125 .18 .25 .062],'string','Parameters','fontsize',14,'fontangle','normal','fontweight','normal');h_push_d_fstep  = uicontrol(h_fig,'callback','inhibit_curve(''d_fstep'');','style','pushbutton','Enable','off', ...   'Units','normalized','position',[.125 .061 .06 .03],'string','SLOWER','fontsize',8,'fontangle','normal', ...   'fontweight','normal');h_push_h_fstep  = uicontrol(h_fig,'callback','inhibit_curve(''h_fstep'');','style','pushbutton','Enable','off', ...   'Units','normalized','position',[.19 .061 .06 .03],'string','FASTER','fontsize',8,'fontangle','normal', ...   'fontweight','normal');h_push_saveNquit  = uicontrol(h_fig,'callback','inhibit_curve(''saveNquit'');','style','pushbutton','Units','normalized', ...    'position',[.41 .08 .08 .075],'string','Save','fontsize',12,'fontangle','normal','fontweight','normal', ...    'enable','on','Visible','on');h_push_restart  = uicontrol(h_fig,'callback','inhibit_curve(''restart'');','style','pushbutton','Units','normalized', ...    'position',[.51 .16 .08 .075],'string','Restart','fontsize',12,'fontangle','normal','fontweight','normal', ...    'enable','on','Visible','on');h_push_abort  = uicontrol(h_fig,'callback','inhibit_curve(''abort'');','style','pushbutton','Units','normalized', ...    'position',[.51 .08 .08 .075],'string','Abort','fontsize',12,'fontangle','normal','fontweight','normal', ...    'enable','on','Visible','on');h_push_stop = uicontrol(h_fig,'callback','inhibit_curve(''stop'');','style','pushbutton','Enable','off','Units','normalized', ...   'position',[.41 .16 .08 .075],'string','Stop','Userdata',[],'fontsize',12,'fontangle','normal','fontweight','normal');h_push_close = uicontrol(h_fig,'callback','inhibit_curve(''close'');','style','pushbutton','Units','normalized', ...   'position',[.44 .0 .12 .075],'string','Close','fontsize',12,'fontangle','normal','fontweight','normal');h_ax1 = axes('position',[.1 .415-0.08 .8 .56+0.08]);	%se3 axis size to accommodate dimensions of image fileh_line1 = plot(-1,-1,'-o');set(h_line1,'color','y');axis([0 1 0 1]);set(h_ax1,'XTick',[]);set(h_ax1,'YTick',[]);box on;h_ax2 = axes('position',[.6 .005 .3 .25]);	%set axis size to accommodate dimensions of image fileaxis([0 1 0 1]);set(h_ax2,'XTick',[]);set(h_ax2,'YTick',[]);box on;filename = fliplr(strtok(fliplr(current_data_file),filesep));h_text1 = text(-.6,2.5,{'Program:' 'Date:'},'fontsize',12,'verticalalignment','top','horizontalalignment','left');h_text2 = text(-.0,2.5,{PROG DATE },'fontsize',12,'color',[.1 .1 .6],'verticalalignment','top','horizontalalignment','right');h_text7 = text(.5,.35,'','fontsize',12,'fontangle','normal','fontweight','normal','color',[.8 .1 .1],'verticalalignment','middle','horizontalalignment','center');h_ax3 = axes('position',[ .1 .005 .3 .25]);	%set axis size to accommodate dimensions of image fileaxis([0 1 0 1]);set(h_ax3,'XTick',[]);set(h_ax3,'YTick',[]);box on;h_text3 = text(.1,.65,{'Low Freq:' 'High Freq:'},'fontsize',9,'verticalalignment','top','horizontalalignment','left');h_text4 = text(.45,.65,{PARAMS(1); PARAMS(2)},'fontsize',9,'color',[.1 .1 .6],'verticalalignment','top','horizontalalignment','right');h_text3b = text(.1,.44,{'# Steps:' ' ' 'Log Steps:'},'fontsize',9,'verticalalignment','top','horizontalalignment','left');h_text4b = text(.45,.44,{step_txt; ' '; log_txt},'fontsize',9,'color',[.1 .1 .6],'verticalalignment','top','horizontalalignment','right');h_text5 = text(.55,.65,{'Low Atten:' 'High Atten:'},'fontsize',9,'verticalalignment','top','horizontalalignment','left');h_text6 = text(.9,.65,{PARAMS(5);PARAMS(6)},'fontsize',9,'color',[.1 .1 .6],'verticalalignment','top','horizontalalignment','right');h_text5b = text(.55,.44,{'Step Size:' 'Ear'},'fontsize',9,'verticalalignment','top','horizontalalignment','left');h_text6b = text(.9,.44,{PARAMS(7);ear_txt},'fontsize',9,'color',[.1 .1 .6],'verticalalignment','top','horizontalalignment','right');