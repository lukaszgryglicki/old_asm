#include <stdio.h>
#include <X11/Xlib.h>
#include <pthread.h>
#include "lib.h"

Display* dsp;
Window win;
GC gc;
int cx,cy;
int wx,wy;

void* func(void* d)
{
 int i;
 int px,py;
 i=0;
 px=wx;
 py=wy;
 while (1) {
 XDrawArc(dsp,win,gc,px-i,py-i,20+2*i,20+2*i,0,360*64);
 /*wx=((5+wx)%cx);
 wy=((5+wy)%cy);*/
 i+=3;
 usleep(30000);
 if (i>=200) break;
 }
}

void bla(int x, int y)
{
 pthread_t pth;
 wx=x;
 wy=y;
 pthread_create(&pth,NULL,func,NULL);
 XDrawArc(dsp,win,gc,x,y,20,20,0,360*64);
}

int run_bzzz()
{
  int s_num;
  int dx,dy;
  int font_h;
  int x,y;
  int done;
  XEvent an_event;

  done=0;
  cx=800;
  cy=600;

  dsp = XOpenDisplay(NULL);
  if (!dsp) {printf("X-server error\n"); return 1;}

  s_num = DefaultScreen(dsp);
  dx = DisplayWidth(dsp, s_num);
  dy = DisplayHeight(dsp, s_num);

  win = XCreateSimpleWindow
  (dsp, RootWindow(dsp, s_num),0, 0, cx, cy, 1,BlackPixel(dsp, s_num),WhitePixel(dsp, s_num));
  XMapWindow(dsp, win);
  XFlush(dsp);

  gc = XCreateGC(dsp, win, 0, NULL);
  if (gc < 0) {printf("GC failed to create!\n"); return 2;}
  XSetForeground(dsp, gc, WhitePixel(dsp, s_num));
  XSetBackground(dsp, gc, BlackPixel(dsp, s_num));

  XSelectInput(dsp, win, ExposureMask | KeyPressMask | KeyReleaseMask | ButtonPressMask | ButtonReleaseMask | Button1MotionMask | Button3MotionMask | Button2MotionMask | PointerMotionMask | StructureNotifyMask);

  XFontStruct* font_info;
  char* font_name = "*-helvetica-*-12-*";
  font_info = XLoadQueryFont(dsp, font_name);
  if (!font_info){ printf("XLoadQueryFont: failed loading font '%s'\n", font_name);return 1;}
  XSetFont(dsp, gc, font_info->fid);
  font_h = font_info->ascent + font_info->descent;

  XSetForeground(dsp,gc,0);

  while (!done)
    {
      XNextEvent(dsp, &an_event);
      switch (an_event.type)
        {
         case Expose:
             //repaint
             break;
        case ConfigureNotify:
             cx = an_event.xconfigure.width;
             cy = an_event.xconfigure.height;
             //repaint
             break;
        case ButtonPress:
	     x = an_event.xbutton.x;
             y = an_event.xbutton.y;
             switch (an_event.xbutton.button)
	          {
                   case Button1:
			 bla(x,y);
		         break;
                   case Button2:
                         break;
		   case Button3:
		         break;
                   default:
                         break;
		  }
        //XClearWindow(display,win);
        break;
        case KeyPress:
	     //XClearWindow(display,win);
	     if (an_event.xkey.keycode == 0x18) done=1;
             break;
        default:
             break;
        }
   }

}

int main()
{
 call_from_lib();
 run_bzzz();
}
