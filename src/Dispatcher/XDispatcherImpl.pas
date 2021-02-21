{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 - 2020 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit XDispatcherImpl;

interface

{$MODE OBJFPC}

uses

    DispatcherIntf,
    EnvironmentIntf,
    ResponseIntf,
    ResponseFactoryIntf,
    RequestIntf,
    RequestFactoryIntf,
    RouteMatcherIntf,
    RouteHandlerIntf,
    MiddlewareExecutorIntf,
    StdInIntf,
    InjectableObjectImpl,
    BaseDispatcherImpl;

type

    (*!---------------------------------------------------
     * Request dispatcher class having capability dispatch
     * request and return response and with middleware support
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *---------------------------------------------------*)
    TXDispatcher = class(TBaseDispatcher)
    private
        fMiddlewareExecutor : IMiddlewareExecutor;
    public
        constructor create(
            const middlewareExecutor : IMiddlewareExecutor;
            const routes : IRouteMatcher;
            const respFactory : IResponseFactory;
            const reqFactory : IRequestFactory
        );
        destructor destroy(); override;

        (*!-------------------------------------------
         * dispatch request
         *--------------------------------------------
         * @param env CGI environment
         * @param stdIn STDIN reader
         * @return response
         *--------------------------------------------*)
        function dispatchRequest(
            const env: ICGIEnvironment;
            const stdIn : IStdIn
        ) : IResponse; override;
    end;

implementation

    constructor TXDispatcher.create(
        const middlewareExecutor : IMiddlewareExecutor;
        const routes : IRouteMatcher;
        const respFactory : IResponseFactory;
        const reqFactory : IRequestFactory
    );
    begin
        inherited create(routes, respFactory, reqFactory);
        fMiddlewareExecutor := middlewareExecutor;
    end;

    destructor TXDispatcher.destroy();
    begin
        fMiddlewareExecutor := nil;
        inherited destroy();
    end;

    function TXDispatcher.dispatchRequest(
        const env: ICGIEnvironment;
        const stdIn : IStdIn
    ) : IResponse;
    var routeHandler : IRouteHandler;
        request : IRequest;
        response : IResponse;
    begin
        //build request instance first to allow request be modified
        //or decorated before we run route matching. This to allow
        //verb tunnelling using special POST parameter such as _method
        request := requestFactory.build(env, stdIn);
        try
            //use CGI environment from request to allow
            //request decorate CGI environment
            response := responseFactory.build(request.env);
            try
                routeHandler := getRouteHandler(request.env);
                try
                    result := fMiddlewareExecutor.execute(
                        request,
                        response,
                        routeHandler
                    );
                finally
                    routeHandler := nil;
                end;
            finally
                response := nil;
            end;
        finally
            request := nil;
        end;
    end;
end.
