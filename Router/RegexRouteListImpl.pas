{*!
 * Fano Web Framework (https://fano.juhara.id)
 *
 * @link      https://github.com/zamronypj/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/zamronypj/fano/blob/master/LICENSE (GPL 2.0)
 *}

unit RegexRouteListImpl;

interface

{$H+}

uses
    RouteListIntf,
    HashListImpl,
    RegexIntf;

type
    TPlaceholder = record
        phName : string;
        phValue : string;
        phFormatRegex : string;
    end;
    TArrayOfPlaceholders = array of TRoutePlaceholder;

    {------------------------------------------------
     interface for any class having capability to
     handler route
     @author Zamrony P. Juhara <zamronypj@yahoo.com>
    -----------------------------------------------}
    TRegexRouteList = class(THashList, IRouteList)
    private
        regex : IRegex;

        function getPlaceholderFromOriginalRoute(
            const originalRouteWithRegex : string
        ) : TArrayOfPlaceholders;

        function getPlaceholderValuesFromUri(
            const originalRouteWithRegex : string;
            const uri : string;
            const placeHolders : TArrayOfPlaceholders
        ) : TArrayOfPlaceholders;

        function replacePlaceholderRegexWithDispatcherRegex(
            const originalRouteWithRegex : string
        ) : string;
        procedure clearRoutes();
        function findRoute(const routeName : string) : pointer;
    public
        constructor create(const regexInst : IRegex);
        destructor destroy(); override;

        function add(const routeName : string; const routeData : pointer) : integer;
        function find(const routeName : string) : pointer;
    end;

implementation

const
    (*-------------------------------------------------
      regex pattern that will match following string format
      and extract placeholder variable name inside {}
      and optional regex (if any)

      /store/{ storeId }/feedback
      /name/{name:[a-zA-Z0-9\-\*\:]+}/{unitId}/edback
      /name/{tr : [a-zA-Z0-9]*? }/{unitId}/edback
    -------------------------------------------------*)
    ROUTE_PLACEHOLDER_REGEX = '\{\s*([a-zA-Z_][a-zA-Z0-9_-]*)\s*(?:\:\s*([^{}]*(?:\{(?-1)\}[^{}]*)*))?\}';

    (*-------------------------------------------------
      regex pattern that will be used to replace original
      route pattern. The replaced route pattern md5-hashed
      will be stored inside list
    -------------------------------------------------*)
    ROUTE_DISPATCH_REGEX = '[^/]+';

type

    TRouteDataRec = record
        placeholders: TArrayOfPlaceholders;
        routeData : pointer;
    end;
    PRouteDataRec = ^TRouteDataRec;

    (*------------------------------------------------
     * get placeholder variable original
     *------------------------------------------------
     * for example for route pattern :
     *  /name/{name:[a-zA-Z0-9\-\*\:]+}/{unitId}/edback
     *
     *  It will returns array of placeholder like below
     *
     * [
     *  {
     *    phName : 'name',
     *    phValue : '',
     *    phFormatRegex : '[a-zA-Z0-9\-\*\:]+',
     *  }
     *  {
     *    phName : 'unitId',
     *    phValue : '',
     *    phFormatRegex : ''
     *  }
     * ]
     *
     * This method will be called when a route pattern is
     * added to route collection. At this time,
     * placeholder value is not yet known ,so phValue field
     * will always be empty
     *
     *---------------------------------------------------*)
    function TRegexRouteList.getPlaceholderFromOriginalRoute(
        const originalRouteWithRegex : string
    ) : TArrayOfPlaceholders;
    var matches : TRegexMatchResult;
    begin
        matches := regex.greedyMatch(
            ROUTE_PLACEHOLDER_REGEX,
            originalRouteWithRegex
        );
    end;

    (*------------------------------------------------
     * get placeholder value from uri
     *------------------------------------------------
     * after a route is matched, then this method will be
     * called with matched route, original uri and placeholder
     * for example for route pattern :
     *  /name/{name:[a-zA-Z0-9\-\*\:]+}/{unitId}/edback
     * and actual Request Uri
     * /name/juhara/nice/edback
     *
     *  It will returns array of placeholder like below
     *
     * [
     *  {
     *    phName : 'name'
     *    phValue : 'juhara'
     *    phFormatRegex : '[a-zA-Z0-9\-\*\:]+',
     *  }
     *  {
     *    phName : 'unitId'
     *    phValue : 'nice'
     *    phFormatRegex : ''
     *  }
     * ]
     *
     *---------------------------------------------------*)
     function TRegexRouteList.getPlaceholderValuesFromUri(
         const uri : string;
         const placeHolders : TArrayOfPlaceholders
     ) : TArrayOfPlaceholders;
    var matches : TRegexMatchResult;
    begin

        matches := regex.greedyMatch(
            ROUTE_DISPATCH_REGEX,
            originalRouteWithRegex
        );
    end;
    constructor TRegexRouteList.create(const regexInst : IRegex);
    begin
        regex := regexInst;
    end;

    destructor TRegexRouteList.destroy();
    begin
        inherited destroy();
        clearRoutes();
        regex := nil;
    end;

    procedure TRegexRouteList.clearRoutes();
    var i, len : integer;
        routeRec : PRouteDataRec;
    begin
        len := count();
        for i := len -1 downto 0 do
        begin
            routeRec := get(i);
            setLength(routeRec^.placeholders, 0);
            routeRec^.routeData := nil;
            dispose(routeRec);
            delete(i);
        end;
    end;

    (*!------------------------------------------------
     * add route pattern to list
     *-------------------------------------------------
     * @param routeName original route as defined by app
     *   /name/{name:[a-zA-Z0-9\-\*\:]+}/{unitId}/edback
     * @param routeData, pointer to route data (such handler, etc)
     * @return integer index of added item in list
     *-------------------------------------------------
     *
     * If we have following input route name
     *   /name/{name:[a-zA-Z0-9\-\*\:]+}/{unitId}/edback
     * (1) we will extract placeholder data
     *     into array of placeholder
     *     [
     *         {
     *             phName : 'name'
     *             phFormaRegex : '[a-zA-Z0-9\-\*\:]+',
     *         },
     *         {
     *             phName : 'unitId'
     *             phFormatRegex : ''
     *         }
     *     ]
     * (2) replace route name into new regex string (transformed route name) as
     *   /name/[^/]+/[^/]+/edback
     * (3) store transformed route name into list
     *---------------------------------------------------*)
    function TRegexRouteList.add(const routeName : string; const routeData : pointer) : integer;
    var transformedRouteName : string;
        placeholders : TArrayOfPlaceholders;
        routeRec : PRouteDataRec;
    begin
        new(routeRec);
        routeRec^.placeholders := getPlaceholderFromOriginalRoute(routeName);
        routeRec^.routeData := routeData;

        (*------------------------------------------------
         * replace original route pattern :
         *   /name/{name:[a-zA-Z0-9\-\*\:]+}/{unitId}/edback
         *
         * into route pattern ready for dispatch
         * /name/[^/]+/[^/]+/edback
         *
         * See ROUTE_DISPATCH_REGEX constant
         *---------------------------------------------------*)
        transformedRouteName := regex.replace(
            ROUTE_PLACEHOLDER_REGEX,
            routeName,
            ROUTE_DISPATCH_REGEX
        );

        result := inherited add(transformedRouteName, routeRec);
    end;

    function TRegexRouteList.combineRegexRoutes() : string;
    var i, len : integer;
    begin
        //if we get here, it is assumed that count will be > 0
        result := '(?:';
        len := count();
        for i:=0 to len-1 do
        begin
            routeRegex := keyOfIndex(i);
            if (i < len-1) then
            begin
                result := result + routeRegex +'|';
            end else
            begin
                result := result + routeRegex;
            end;
        end;
        result := result + ')';
    end;

    (*------------------------------------------------
     * match request uri with route list
     *------------------------------------------------
     * @param requestUri, original request uri
     * @return routeData of matched route
     *-------------------------------------------------
     * For example, if we have following uri
     *   /name/juhara/nice/edback
     * and following registered route patterns
     *  (1) /name/([^/]+)/([^/]+)/edback
     *  (2) /article/([^/]+)/([^/]+)
     *  (3) /articles/([^/]+)/([^/]+)
     *
     * (i) We will combine all registered route patterns in list into one
     * string regex in form, so we can match all routes using only one
     * regex matching call. (?:) is non capturing group so only inside parenthesis
     * that will be captured
     *
     *  (?:
     *  (/name/([^/]+)/([^/]+)/edback)|
     *  (/article/([^/]+)/([^/]+)|
     *  (/articles/([^/]+)/([^/]+)
     *  )
     *
     * (ii) Based on matched group (the second non empty group),
     * we can get index to the list of routes list.
     * (iii) parse capture group based on its placeholder to get value
     * (iv) return route data with its placeholder data
     *---------------------------------------------------*)
    function TRegexRouteList.findRoute(const requestUri : string) : pointer;
    var combinedRegex : string;
        matches : TRegexMatchResult;
        placeholderRegex : TRegexMatchResult;
        data :PRouteDataRec;
    begin
        combinedRegex := combineRegexRoutes();
        matches := regex.match(combinedRegex, requestUri);
        if (matches.matched) then
        begin
            data := inherited find(matches.matches[0]);
            if (data <> nil) then
            begin
                if (length(data.phFormatRegex) > 0) then
                begin
                    //if we get here, placeholder expect value to be in format
                    //as specified by phFormatRegex, test further
                    placeholherRegex := regex.match(data.formatRegex, matches.matches[0]);
                    if (placeholderRegex.matched) then
                    begin
                        data.phValue := matches.matches[0];
                    end else
                    begin
                        //assume not found or some other value
                        result := nil;
                    end;
                end else
                begin
                    data.phValue := matches.matches[0];
                end;
                //TODO:return also placeholder!!
                result := data.routeData;
            end else
            begin
                result := nil;
            end;
        end else
        begin
            result := nil;
        end;
    end;

    (*------------------------------------------------
     * match request uri with route list and return
     * its associated data
     *---------------------------------------------------*)
    function TRegexRouteList.find(const requestUri : string) : pointer;
    begin
        if (count() <> 0) then
        begin
            result := findRoute(requestUri);
        end else
        begin
          result :=nil;
        end;
    end;
end.