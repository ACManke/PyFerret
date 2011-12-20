/*
 * Drawing commands
 */
#include <Python.h> /* make sure Python.h is first */
#include <stdio.h>
#include <string.h>
#include "grdel.h"
#include "pyferret.h"

/*
 * Assigns the transformation values my, sx, sy, dx, and dy used
 * to convert user coordinate (userx, usery) to device coordinate
 * (devx, devy) using the formulae:
 *    devx = userx * sx + dx
 *    devy = (my - usery) * sy + dy
 */
static void getTransformValues(double *my, double *sx, double *sy,
                               double *dx, double *dy)
{
   float lftfrc, rgtfrc, btmfrc, topfrc;
   float lftcrd, rgtcrd, btmcrd, topcrd;
   float winwidth, winheight;
   double devlft, devtop, devwidth, devheight;
   double usrlft, usrtop, usrwidth, usrheight;

   fgd_get_view_limits_(&lftfrc, &rgtfrc, &btmfrc, &topfrc,
                        &lftcrd, &rgtcrd, &btmcrd, &topcrd);
   fgd_get_window_size_(&winwidth, &winheight);

   devlft     = (double) lftfrc * (double) winwidth;
   devwidth   = (double) rgtfrc * (double) winwidth;
   devwidth  -= devlft;
   devtop     = (1.0 - (double) topfrc) * (double) winheight;
   devheight  = (1.0 - (double) btmfrc) * (double) winheight;
   devheight -= devtop;

   usrlft = (double) lftcrd;
   usrwidth = (double) rgtcrd - usrlft;
   usrtop = 0.0;
   usrheight = (double) topcrd - (double) btmcrd;

   *my = (double) topcrd;
   *sx = devwidth / usrwidth;
   *sy = devheight / usrheight;
   *dx = devlft - (*sx) * usrlft;
   *dy = devtop - (*sy) * usrtop;
}

/*
 * Draws connected line segments.
 *
 * Arguments:
 *     window: Window with an active View to draw in
 *     ptsx: user X-coordinates of the endpoint
 *     ptsy: user Y-coordinates of the endpoints
 *     numpts: number of coordinates in ptsx and ptsy to use
 *     pen: Pen to use to draw the line segments
 *
 * Returns success or failure.  If failure, grdelerrmsg contains
 * an explanatory message.
 */
grdelBool grdelDrawMultiline(grdelType window, const float ptsx[],
               const float ptsy[], int numpts, grdelType pen)
{
    PyObject *bindings;
    PyObject *penobj;
    PyObject *xtuple;
    PyObject *ytuple;
    PyObject *fltobj;
    PyObject *result;
    double my, sx, sy, dx, dy;
    double transval;
    int k;

#ifdef VERBOSEDEBUG
    fprintf(debuglogfile, "grdelDrawMultiline called: "
            "window = %X, pen = %X\n", window, pen);
    fflush(debuglogfile);
#endif

    bindings = grdelWindowVerify(window);
    if ( bindings == NULL  ) {
        strcpy(grdelerrmsg, "grdelDrawMultiline: window argument is not "
                            "a grdel Window");
        return (grdelBool) 0;
    }
    penobj = grdelPenVerify(pen, window);
    if ( penobj == NULL ) {
        strcpy(grdelerrmsg, "grdelDrawMultiline: pen argument is not "
                            "a valid grdel Pen for the window");
        return (grdelBool) 0;
    }
    if ( numpts <= 1 ) {
        strcpy(grdelerrmsg, "grdelDrawMultiline: invalid number of points");
        return (grdelBool) 0;
    }

    /* Get the transform values for converting user to device coordinates */
    getTransformValues(&my, &sx, &sy, &dx, &dy);

    xtuple = PyTuple_New( (Py_ssize_t) numpts );
    if ( xtuple == NULL ) {
        PyErr_Clear();
        strcpy(grdelerrmsg, "grdelDrawMultiline: problems creating "
                            "a Python tuple");
        return (grdelBool) 0;
    }
    for (k = 0; k < numpts; k++) {
        transval = (double) (ptsx[k]) * sx + dx;
        fltobj = PyFloat_FromDouble(transval);
        if ( fltobj == NULL ) {
            PyErr_Clear();
            strcpy(grdelerrmsg, "grdelDrawMultiline: problems creating "
                                "a Python float");
            Py_DECREF(xtuple);
            return (grdelBool) 0;
        }
        /* PyTuple_SET_ITEM steals the reference to fltobj */
        PyTuple_SET_ITEM(xtuple, (Py_ssize_t) k, fltobj);
    }

    ytuple = PyTuple_New( (Py_ssize_t) numpts );
    if ( ytuple == NULL ) {
        PyErr_Clear();
        strcpy(grdelerrmsg, "grdelDrawMultiline: problems creating "
                            "a Python tuple");
        Py_DECREF(xtuple);
        return (grdelBool) 0;
    }
    for (k = 0; k < numpts; k++) {
        transval = (my - (double) (ptsy[k])) * sy + dy;
        fltobj = PyFloat_FromDouble(transval);
        if ( fltobj == NULL ) {
            PyErr_Clear();
            strcpy(grdelerrmsg, "grdelDrawMultiline: problems creating "
                                "a Python float");
            Py_DECREF(ytuple);
            Py_DECREF(xtuple);
            return (grdelBool) 0;
        }
        /* PyTuple_SET_ITEM steals the reference to fltobj */
        PyTuple_SET_ITEM(ytuple, (Py_ssize_t) k, fltobj);
    }

    /*
     * Call the drawMultiline method of the bindings instance.
     * Using 'N' to steal the reference to xtuple and to ytuple.
     */
    result = PyObject_CallMethod(bindings, "drawMultiline", "NNO",
                                 xtuple, ytuple, penobj);
    if ( result == NULL ) {
        sprintf(grdelerrmsg, "grdelDrawMultiline: error when calling "
                "the binding's drawMultiline method: %s", pyefcn_get_error());
        return (grdelBool) 0;
    }
    Py_DECREF(result);

    grdelerrmsg[0] = '\0';
    return (grdelBool) 1;
}

/*
 * Draws discrete points.
 *
 * Arguments:
 *     window: Window with an active View to draw in
 *     ptsx: user X-coordinates of the points
 *     ptsy: user Y-coordinates of the points
 *     numpts: number of coordinates in ptsx and ptsy to use
 *     symbol: Symbol to use to draw a point
 *     color: color of the Symbol
 *     ptsize: size of the symbol (scales with view size)
 *
 * Returns success or failure.  If failure, grdelerrmsg contains
 * an explanatory message.
 */
grdelBool grdelDrawPoints(grdelType window, const float ptsx[],
               const float ptsy[], int numpts, grdelType symbol,
               grdelType color, float ptsize)
{
    PyObject *bindings;
    PyObject *symbolobj;
    PyObject *colorobj;
    PyObject *xtuple;
    PyObject *ytuple;
    PyObject *fltobj;
    PyObject *result;
    double my, sx, sy, dx, dy;
    double transval;
    int k;

#ifdef VERBOSEDEBUG
    fprintf(debuglogfile, "grdelDrawPoints called: "
            "window = %X, symbol = %X, color = %X", window, symbol, color);
    fflush(debuglogfile);
#endif

    bindings = grdelWindowVerify(window);
    if ( bindings == NULL  ) {
        strcpy(grdelerrmsg, "grdelDrawPoints: window argument is not "
                            "a grdel Window");
        return (grdelBool) 0;
    }
    symbolobj = grdelSymbolVerify(symbol, window);
    if ( symbolobj == NULL ) {
        strcpy(grdelerrmsg, "grdelDrawPoints: symbol argument is not "
                            "a valid grdel Symbol for the window");
        return (grdelBool) 0;
    }
    colorobj = grdelColorVerify(color, window);
    if ( colorobj == NULL ) {
        strcpy(grdelerrmsg, "grdelDrawPoints: color argument is not "
                            "a valid grdel Color for the window");
        return (grdelBool) 0;
    }
    if ( numpts <= 0 ) {
        strcpy(grdelerrmsg, "grdelDrawPoints: invalid number of points");
        return (grdelBool) 0;
    }

    /* Get the transform values for converting user to device coordinates */
    getTransformValues(&my, &sx, &sy, &dx, &dy);

    xtuple = PyTuple_New( (Py_ssize_t) numpts );
    if ( xtuple == NULL ) {
        PyErr_Clear();
        strcpy(grdelerrmsg, "grdelDrawPoints: problems creating "
                            "a Python tuple");
        return (grdelBool) 0;
    }
    for (k = 0; k < numpts; k++) {
        transval = (double) (ptsx[k]) * sx + dx;
        fltobj = PyFloat_FromDouble(transval);
        if ( fltobj == NULL ) {
            PyErr_Clear();
            strcpy(grdelerrmsg, "grdelDrawPoints: problems creating "
                                "a Python float");
            Py_DECREF(xtuple);
            return (grdelBool) 0;
        }
        /* PyTuple_SET_ITEM steals the reference to fltobj */
        PyTuple_SET_ITEM(xtuple, (Py_ssize_t) k, fltobj);
    }

    ytuple = PyTuple_New( (Py_ssize_t) numpts );
    if ( ytuple == NULL ) {
        PyErr_Clear();
        strcpy(grdelerrmsg, "grdelDrawPoints: problems creating "
                            "a Python tuple");
        Py_DECREF(xtuple);
        return (grdelBool) 0;
    }
    for (k = 0; k < numpts; k++) {
        transval = (my - (double) (ptsy[k])) * sy + dy;
        fltobj = PyFloat_FromDouble(transval);
        if ( fltobj == NULL ) {
            PyErr_Clear();
            strcpy(grdelerrmsg, "grdelDrawPoints: problems creating "
                                "a Python float");
            Py_DECREF(ytuple);
            Py_DECREF(xtuple);
            return (grdelBool) 0;
        }
        /* PyTuple_SET_ITEM steals the reference to fltobj */
        PyTuple_SET_ITEM(ytuple, (Py_ssize_t) k, fltobj);
    }

    /*
     * Call the drawPoints method of the bindings instance.
     * Using 'N' to steal the reference to xtuple and to ytuple.
     */
    result = PyObject_CallMethod(bindings, "drawPoints", "NNOOd",
                                 xtuple, ytuple, symbolobj,
                                 colorobj, (double) ptsize);
    if ( result == NULL ) {
        sprintf(grdelerrmsg, "grdelDrawPoints: error when calling "
                "the binding's drawPoints method: %s", pyefcn_get_error());
        return (grdelBool) 0;
    }
    Py_DECREF(result);

    grdelerrmsg[0] = '\0';
    return (grdelBool) 1;
}

/*
 * Draws a polygon.
 *
 * Arguments:
 *     window: Window with an active View to draw in
 *     ptsx: user X-coordinates of the vertices
 *     ptsy: user Y-coordinates of the vertices
 *     numpts: number of coordinates in ptsx and ptsy to use
 *     brush: Brush to use to fill the polygon; if NULL,
 *             the polygon will not be filled
 *     pen: Pen to use to outline the polygon; if NULL
 *             the polygon will not be outlined
 *
 * Returns success or failure.  If failure, grdelerrmsg contains
 * an explanatory message.
 */
grdelBool grdelDrawPolygon(grdelType window, const float ptsx[],
               const float ptsy[], int numpts, grdelType brush,
               grdelType pen)
{
    PyObject *bindings;
    PyObject *brushobj;
    PyObject *penobj;
    PyObject *xtuple;
    PyObject *ytuple;
    PyObject *fltobj;
    PyObject *result;
    double my, sx, sy, dx, dy;
    double transval;
    int k;

#ifdef VERBOSEDEBUG
    fprintf(debuglogfile, "grdelDrawPolygon called: "
            "window = %X, brush = %X, pen = %X\n", window, brush, pen);
    fflush(debuglogfile);
#endif

    bindings = grdelWindowVerify(window);
    if ( bindings == NULL  ) {
        strcpy(grdelerrmsg, "grdelDrawPolygon: window argument is not "
                            "a grdel Window");
        return (grdelBool) 0;
    }
    if ( (brush == NULL) && (pen == NULL) ) {
        strcpy(grdelerrmsg, "grdelDrawPolygon: neither a pen nor "
                            "a brush was specified");
        return (grdelBool) 0;
    }
    if ( brush != NULL ) {
        brushobj = grdelBrushVerify(brush, window);
        if ( brushobj == NULL ) {
            strcpy(grdelerrmsg, "grdelDrawPolygon: brush argument is not "
                                "a valid grdel Brush for the window");
            return (grdelBool) 0;
        }
    }
    else
        brushobj = Py_None;
    if ( pen != NULL ) {
        penobj = grdelPenVerify(pen, window);
        if ( penobj == NULL ) {
            strcpy(grdelerrmsg, "grdelDrawPolygon: pen argument is not "
                                "a valid grdel Pen for the window");
            return (grdelBool) 0;
        }
    }
    else
        penobj = Py_None;
    if ( numpts <= 2 ) {
        strcpy(grdelerrmsg, "grdelDrawPolygon: invalid number of points");
        return (grdelBool) 0;
    }

    /* Get the transform values for converting user to device coordinates */
    getTransformValues(&my, &sx, &sy, &dx, &dy);

    xtuple = PyTuple_New( (Py_ssize_t) numpts );
    if ( xtuple == NULL ) {
        PyErr_Clear();
        strcpy(grdelerrmsg, "grdelDrawPolygon: problems creating "
                            "a Python tuple");
        return (grdelBool) 0;
    }
    for (k = 0; k < numpts; k++) {
        transval = (double) (ptsx[k]) * sx + dx;
        fltobj = PyFloat_FromDouble(transval);
        if ( fltobj == NULL ) {
            PyErr_Clear();
            strcpy(grdelerrmsg, "grdelDrawPolygon: problems creating "
                                "a Python float");
            Py_DECREF(xtuple);
            return (grdelBool) 0;
        }
        /* PyTuple_SET_ITEM steals the reference to fltobj */
        PyTuple_SET_ITEM(xtuple, (Py_ssize_t) k, fltobj);
    }

    ytuple = PyTuple_New( (Py_ssize_t) numpts );
    if ( ytuple == NULL ) {
        PyErr_Clear();
        strcpy(grdelerrmsg, "grdelDrawPolygon: problems creating "
                            "a Python tuple");
        Py_DECREF(xtuple);
        return (grdelBool) 0;
    }
    for (k = 0; k < numpts; k++) {
        transval = (my - (double) (ptsy[k])) * sy + dy;
        fltobj = PyFloat_FromDouble(transval);
        if ( fltobj == NULL ) {
            PyErr_Clear();
            strcpy(grdelerrmsg, "grdelDrawPolygon: problems creating "
                                "a Python float");
            Py_DECREF(ytuple);
            Py_DECREF(xtuple);
            return (grdelBool) 0;
        }
        /* PyTuple_SET_ITEM steals the reference to fltobj */
        PyTuple_SET_ITEM(ytuple, (Py_ssize_t) k, fltobj);
    }

    /*
     * Call the drawPolygon method of the bindings instance.
     * Using 'N' to steal the reference to xtuple and to ytuple.
     */
    result = PyObject_CallMethod(bindings, "drawPolygon", "NNOO",
                                 xtuple, ytuple, brushobj, penobj);
    if ( result == NULL ) {
        sprintf(grdelerrmsg, "grdelDrawPolygon: error when calling "
                "the binding's drawPolygon method: %s", pyefcn_get_error());
        return (grdelBool) 0;
    }
    Py_DECREF(result);

    grdelerrmsg[0] = '\0';
    return (grdelBool) 1;
}

/*
 * Draws a rectangle.
 *
 * Arguments:
 *     window: Window with an active View to draw in
 *     left: user X-coordinate of the left edge
 *     bottom: user Y-coordinate of the bottom edge
 *     right: user X-coordinate of the right edge
 *     top: user Y-coordinate of the top edge
 *     brush: Brush to use to fill the rectangle; if NULL,
 *             the rectangle will not be filled
 *     pen: Pen to use to outline the rectangle; if NULL
 *             the rectangle will not be outlined
 *
 * Returns success or failure.  If failure, grdelerrmsg contains
 * an explanatory message.
 */
grdelBool grdelDrawRectangle(grdelType window, float left, float bottom,
               float right, float top, grdelType brush, grdelType pen)
{
    PyObject *bindings;
    PyObject *brushobj;
    PyObject *penobj;
    PyObject *result;
    double my, sx, sy, dx, dy;
    double trlft, trbtm, trrgt, trtop;

#ifdef VERBOSEDEBUG
    fprintf(debuglogfile, "grdelDrawRectangle called: "
            "window = %X, brush = %X, pen = %X\n", window, brush, pen);
    fflush(debuglogfile);
#endif

    bindings = grdelWindowVerify(window);
    if ( bindings == NULL  ) {
        strcpy(grdelerrmsg, "grdelDrawRectangle: window argument is not "
                            "a grdel Window");
        return (grdelBool) 0;
    }
    if ( (brush == NULL) && (pen == NULL) ) {
        strcpy(grdelerrmsg, "grdelDrawRectangle: neither a pen nor "
                            "a brush was specified");
        return (grdelBool) 0;
    }
    if ( brush != NULL ) {
        brushobj = grdelBrushVerify(brush, window);
        if ( brushobj == NULL ) {
            strcpy(grdelerrmsg, "grdelDrawRectangle: brush argument is not "
                                "a valid grdel Brush for the window");
            return (grdelBool) 0;
        }
    }
    else
        brushobj = Py_None;
    if ( pen != NULL ) {
        penobj = grdelPenVerify(pen, window);
        if ( penobj == NULL ) {
            strcpy(grdelerrmsg, "grdelDrawRectangle: pen argument is not "
                                "a valid grdel Pen for the window");
            return (grdelBool) 0;
        }
    }
    else
        penobj = Py_None;

    /* Get the transform values for converting user to device coordinates */
    getTransformValues(&my, &sx, &sy, &dx, &dy);
    trlft = (double) left * sx + dx;
    trrgt = (double) right * sx + dx;
    trtop = (my - (double) top) * sy + dy;
    trbtm = (my - (double) bottom) * sy + dy;

    /*
     * Call the drawRectangle method of the bindings instance.
     */
    result = PyObject_CallMethod(bindings, "drawRectangle", "ddddOO",
                                 trlft, trbtm, trrgt, trtop,
                                 brushobj, penobj);
    if ( result == NULL ) {
        sprintf(grdelerrmsg, "grdelDrawRectangle: error when calling "
                "the binding's drawRectangle method: %s", pyefcn_get_error());
        return (grdelBool) 0;
    }
    Py_DECREF(result);

    grdelerrmsg[0] = '\0';
    return (grdelBool) 1;
}

/*
 * Draws a filled rectangle using an array of solid colors.
 * The rectangle is divided into a given number of equally
 * spaced rows and a number of equally spaced columns.  Each
 * of these cells is then filled with a color (using a solid
 * brush) from the corresponding element in an array of colors.
 *
 * Arguments:
 *     window: Window with an active View to draw in
 *     left: user X-coordinate of the left edge
 *     bottom: user Y-coordinate of the bottom edge
 *     right: user X-coordinate of the right edge
 *     top: user Y-coordinate of the top edge
 *     numrows: number of equally spaced rows
 *              to subdivide the rectangle into
 *     numcols: number of equally spaced columns
 *     	        to subdivide the rectangle into
 *     colors: flattened column-major 2-D array of colors
 *              specifying the color of each corresponding cell
 *
 * Returns success or failure.  If failure, grdelerrmsg contains
 * an explanatory message.
 */
grdelBool grdelDrawMulticolorRectangle(grdelType window,
               float left, float bottom, float right, float top,
               int numrows, int numcols, const grdelType colors[])
{
    PyObject *bindings;
    PyObject *colortuple;
    PyObject *colorobj;
    PyObject *result;
    int numcolors;
    double my, sx, sy, dx, dy;
    double trlft, trbtm, trrgt, trtop;
    int k;

#ifdef VERBOSEDEBUG
    fprintf(debuglogfile, "grdelDrawMulticolorRectangle called: "
            "window = %X\n", window);
    fflush(debuglogfile);
#endif

    bindings = grdelWindowVerify(window);
    if ( bindings == NULL  ) {
        strcpy(grdelerrmsg, "grdelDrawMulticolor: window argument is not "
                            "a grdel Window");
        return (grdelBool) 0;
    }
    numcolors = numrows * numcols;
    if ( (numrows <= 0)  || (numcols <= 0) || (numcolors <= 0) ) {
        strcpy(grdelerrmsg, "grdelDrawMulticolor: invalid numrows and/or "
                            "numcols value");
        return (grdelBool) 0;
    }

    /* Get the transform values for converting user to device coordinates */
    getTransformValues(&my, &sx, &sy, &dx, &dy);
    trlft = (double) left * sx + dx;
    trrgt = (double) right * sx + dx;
    trtop = (my - (double) top) * sy + dy;
    trbtm = (my - (double) bottom) * sy + dy;

    colortuple = PyTuple_New( (Py_ssize_t) numcolors );
    if ( colortuple == NULL ) {
        PyErr_Clear();
        strcpy(grdelerrmsg, "grdelDrawMulticolor: problems creating "
                            "a Python tuple");
        return (grdelBool) 0;
    }
    for (k = 0; k < numrows * numcols; k++) {
        colorobj = grdelColorVerify(colors[k], window);
        if ( colorobj == NULL  ) {
            sprintf(grdelerrmsg, "grdelDrawMulticolor: colors[%d] is not "
                                 "a valid grdel Color for the window", k);
            Py_DECREF(colortuple);
            return (grdelBool) 0;
        }
        /*
         * PyTuple_SET_ITEM steals a reference to colorobj,
         * so increment the reference count on it.
         */
        Py_INCREF(colorobj);
        PyTuple_SET_ITEM(colortuple, (Py_ssize_t) k, colorobj);
    }

    /*
     * Call the drawMulticolorRectangle method of the bindings instance.
     * Using 'N' to steal the reference to colortuple.
     */
    result = PyObject_CallMethod(bindings, "drawMulticolorRectangle", "ddddiiN",
                                 trlft, trbtm, trrgt, trtop,
                                 numrows, numcols, colortuple);
    if ( result == NULL ) {
        sprintf(grdelerrmsg, "grdelDrawMulticolor: error when calling "
                "the binding's drawMulticolorRectangle method: %s", pyefcn_get_error());
        return (grdelBool) 0;
    }
    Py_DECREF(result);

    grdelerrmsg[0] = '\0';
    return (grdelBool) 1;
}

/*
 * Draws text.
 *
 * Arguments:
 *     window: Window with an active View to draw in
 *     text: text string to draw
 *     textlen: actual length of the text string
 *     startx: user X-coordinate of the beginning
 *              of the text baseline
 *     starty: user Y-coordinate of the beginning 
 *              of the text baseline
 *     font: font to use
 *     color: color to use (as a solid brush or pen)
 *     rotate: angle of the text baseline in degrees
 *              clockwise from horizontal
 *
 * Returns success or failure.  If failure, grdelerrmsg contains
 * an explanatory message.
 */
grdelBool grdelDrawText(grdelType window, const char *text, int textlen,
               float startx, float starty, grdelType font, grdelType color,
               float rotate)
{
    PyObject *bindings;
    PyObject *fontobj;
    PyObject *colorobj;
    PyObject *result;
    double my, sx, sy, dx, dy;
    double trstx, trsty;

#ifdef VERBOSEDEBUG
    fprintf(debuglogfile, "grdelDrawText called: "
            "window = %X, font = %X, color = %X\n", window, font, color);
    fflush(debuglogfile);
#endif

    bindings = grdelWindowVerify(window);
    if ( bindings == NULL  ) {
        strcpy(grdelerrmsg, "grdelDrawText: window argument is not "
                            "a grdel Window");
        return (grdelBool) 0;
    }
    fontobj = grdelFontVerify(font, window);
    if ( fontobj == NULL ) {
        strcpy(grdelerrmsg, "grdelDrawText: font argument is not "
                            "a valid grdel Font for the window");
        return (grdelBool) 0;
    }
    colorobj = grdelColorVerify(color, window);
    if ( colorobj == NULL ) {
        strcpy(grdelerrmsg, "grdelDrawText: color argument is not "
                            "a valid grdel Color for the window");
        return (grdelBool) 0;
    }

    /* Get the transform values for converting user to device coordinates */
    getTransformValues(&my, &sx, &sy, &dx, &dy);
    trstx = (double) startx * sx + dx;
    trsty = (my - (double) starty) * sy + dy;

    /* Call the drawText method of the bindings instance. */
    result = PyObject_CallMethod(bindings, "drawText", "s#ddOOd",
                                 text, textlen, trstx, trsty,
                                 fontobj, colorobj, (double) rotate);
    if ( result == NULL ) {
        sprintf(grdelerrmsg, "grdelDrawText: Error when calling "
                "the binding's drawText method: %s", pyefcn_get_error());
        return (grdelBool) 0;
    }
    Py_DECREF(result);

    grdelerrmsg[0] = '\0';
    return (grdelBool) 1;
}

/*
 * Draws connected line segments.
 *
 * Input Arguments:
 *     window: Window with an active View to draw in
 *     ptsx: user X-coordinates of the endpoints
 *     ptsy: user Y-coordinates of the endpoints
 *     numpts: number of coordinates in ptsx and ptsy to use
 *     pen: Pen to use to draw the line segments
 * Output Arguments:
 *     success: non-zero if successful; zero if an error occurred.
 *              Use fgderrmsg_ to retrieve the error message.
 */
void fgddrawmultiline_(int *success, void **window, float ptsx[],
               float ptsy[], int *numpts, void **pen)
{
    grdelBool result;

    result = grdelDrawMultiline(*window, ptsx, ptsy, *numpts, *pen);
    *success = result;
}

/*
 * Draws discrete points.
 *
 * Input Arguments:
 *     window: Window with an active View to draw in
 *     ptsx: user X-coordinates of the points
 *     ptsy: user Y-coordinates of the points
 *     numpts: number of coordinates in ptsx and ptsy to use
 *     symbol: Symbol to use to draw a point
 *     color: color of the Symbol
 *     ptsize: size of the symbol (scales with view size)
 * Output Arguments:
 *     success: non-zero if successful; zero if an error occurred.
 *              Use fgderrmsg_ to retrieve the error message.
 */
void fgddrawpoints_(int *success, void **window, float ptsx[],
                    float ptsy[], int *numpts, void **symbol,
                    void **color, float *ptsize)
{
    grdelBool result;

    result = grdelDrawPoints(*window, ptsx, ptsy, *numpts, *symbol,
                             *color, *ptsize);
    *success = result;
}

/*
 * Draws a polygon.
 *
 * Input Arguments:
 *     window: Window with an active View to draw in
 *     ptsx: user X-coordinates of the vertices
 *     ptsy: user Y-coordinates of the vertices 
 *     numpts: number of coordinates in ptsx and ptsy to use
 *     brush: Brush to use to fill the polygon; if NULL,
 *             the polygon will not be filled
 *     pen: Pen to use to outline the polygon; if NULL
 *             the polygon will not be outlined
 * Output Arguments:
 *     success: non-zero if successful; zero if an error occurred.
 *              Use fgderrmsg_ to retrieve the error message.
 */
void fgddrawpolygon_(int *success, void **window, float ptsx[],
                     float ptsy[], int *numpts, void **brush, void **pen)
{
    grdelBool result;

    result = grdelDrawPolygon(*window, ptsx, ptsy, *numpts, *brush, *pen);
    *success = result;
}

/*
 * Draws a rectangle.
 *
 * Input Arguments:
 *     window: Window with an active View to draw in
 *     left: user X-coordinate of the left edge 
 *     bottom: user Y-coordinate of the bottom edge 
 *     right: user X-coordinate of the right edge 
 *     top: user Y-coordinate of the top edge 
 *     brush: Brush to use to fill the rectangle; if NULL,
 *             the rectangle will not be filled
 *     pen: Pen to use to outline the rectangle; if NULL
 *             the rectangle will not be outlined
 * Output Arguments:
 *     success: non-zero if successful; zero if an error occurred.
 *              Use fgderrmsg_ to retrieve the error message.
 */
void fgddrawrect_(int *success, void **window, float *left, float *bottom,
                  float *right, float *top, void **brush, void **pen)
{
    grdelBool result;

    result = grdelDrawRectangle(*window, *left, *bottom, *right, *top,
                                *brush, *pen);
    *success = result;
}

/*
 * Draws a filled rectangle using an array of solid colors.
 * The rectangle is divided into a given number of equally
 * spaced rows and a number of equally spaced columns.  Each
 * of these cells is then filled with a color (using a solid
 * brush) from the corresponding element in an array of colors.
 *
 * Input Arguments:
 *     window: Window with an active View to draw in
 *     left: user X-coordinate of the left edge
 *     bottom: user Y-coordinate of the bottom edge 
 *     right: user X-coordinate of the right edge 
 *     top: user Y-coordinate of the top edge 
 *     numrows: number of equally spaced rows
 *              to subdivide the rectangle into
 *     numcols: number of equally spaced columns
 *              to subdivide the rectangle into
 *     colors: flattened column-major 2-D array of colors
 *              specifying the color of each corresponding cell
 * Output Arguments:
 *     success: non-zero if successful; zero if an error occurred.
 *              Use fgderrmsg_ to retrieve the error message.
 */
void fgddrawmulticolor_(int *success, void **window, float *left,
                        float *bottom, float *right, float *top,
                        int *numrows, int *numcols, void *colors[])
{
    grdelBool result;

    result = grdelDrawMulticolorRectangle(*window, *left, *bottom, *right,
                                          *top, *numrows, *numcols, colors);
    *success = result;
}

/*
 * Draws text.
 *
 * Input Arguments:
 *     window: the Window with an active View to draw in
 *     text: text string to draw
 *     textlen: actual length of the text string
 *     startx: user X-coordinate of the beginning baseline
 *              of the text 
 *     starty: user Y-coordinate of the beginning baseline
 *              of the text 
 *     font: font to use 
 *     color: color to use (as a solid brush or pen)
 *     rotate: angle of the baseline in degrees
 *              clockwise from horizontal
 * Output Arguments:
 *     success: non-zero if successful; zero if an error occurred.
 *              Use fgderrmsg_ to retrieve the error message.
 */
void fgddrawtext_(int *success, void **window, char *text, int *textlen,
                  float *startx, float *starty, void **font, void **color,
                  float *rotate)
{
    grdelBool result;

    result = grdelDrawText(*window, text, *textlen, *startx, *starty,
                           *font, *color, *rotate);
    *success = result;
}

