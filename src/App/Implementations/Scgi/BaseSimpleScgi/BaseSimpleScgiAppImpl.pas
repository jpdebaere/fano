{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}
unit BaseSimpleScgiAppImpl;

interface

{$MODE OBJFPC}

uses

    DaemonAppImpl,
    DependencyContainerIntf,
    DispatcherIntf,
    EnvironmentIntf,
    ErrorHandlerIntf,
    OutputBufferIntf,
    RunnableWithDataNotifIntf,
    StdOutIntf;

type

    (*!-----------------------------------------------
     * Base abstract class that implements IWebApplication
     * and provide basic default for easier setup for SCGI
     * web application
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    TBaseSimpleScgiWebApplication = class(TDaemonWebApplication)
    protected
        function initDispatcher(const container : IDependencyContainer) : IDispatcher; override;
    public
        (*!-----------------------------------------------
         * constructor
         *------------------------------------------------
         * @param container dependency container
         * @param env CGI environment instance
         * @param errHandler error handler
         *----------------------------------------------
         * This is provided to simplify thing by providing
         * default service provider
         *-----------------------------------------------*)
        constructor create(
            const workerServer : IRunnableWithDataNotif;
            const container : IDependencyContainer = nil;
            const errHandler : IErrorHandler = nil;
            const dispatcherInst : IDispatcher = nil
        );

    end;

implementation

uses

    SysUtils,
    ProtocolProcessorIntf,
    DependencyContainerImpl,
    DependencyListImpl,
    ErrorHandlerImpl,
    RouterIntf,
    RouteMatcherIntf,
    SimpleRouterFactoryImpl,
    SimpleDispatcherFactoryImpl,
    ScgiProcessorImpl,
    ScgiParserImpl,
    OutputBufferImpl,
    ScgiStdOutWriterImpl,
    StdInIntf,
    StdInFromStreamImpl,
    NullStreamAdapterImpl,
    RequestResponseFactoryImpl,
    NonBlockingProtocolProcessorImpl,
    HashListImpl;

    (*!-----------------------------------------------
     * constructor
     *------------------------------------------------
     * @param container dependency container
     * @param env CGI environment instance
     * @param errHandler error handler
     *----------------------------------------------
     * This is provided to simplify thing by providing
     * default service provider
     *-----------------------------------------------*)
    constructor TBaseSimpleScgiWebApplication.create(
        const workerServer : IRunnableWithDataNotif;
        const container : IDependencyContainer = nil;
        const errHandler : IErrorHandler = nil;
        const dispatcherInst : IDispatcher = nil
    );
    var appContainer :  IDependencyContainer;
        appErr : IErrorHandler;
        appDispatcher : IDispatcher;
        appProcessor : IProtocolProcessor;
        appOutputBuffer : IOutputBuffer;
        appStdOutWriter : IStdOut;
        appStdIn : IStdIn;
        dispatcherId : string;
        routerId : string;
    begin
        appContainer := container;
        if (appContainer = nil) then
        begin
            appContainer := TDependencyContainer.create(TDependencyList.create());
        end;

        appErr := errHandler;
        if (appErr = nil) then
        begin
            appErr := TErrorHandler.create();
        end;

        appProcessor := TNonBlockingProtocolProcessor.create(
            TScgiProcessor.create(TScgiParser.create()),
            THashList.create()
        );
        appOutputBuffer := TOutputBuffer.create();
        appStdOutWriter := TScgiStdOutWriter.create();
        appStdIn := TStdInFromStream.create(TNullStreamAdapter.create());

        routerId := GUIDToString(IRouteMatcher);
        if (not appContainer.has(routerId)) then
        begin
            appContainer.add(routerId, TSimpleRouterFactory.create());
            appContainer.alias(GUIDToString(IRouter), routerId);
        end;

        appDispatcher := dispatcherInst;

        dispatcherId := GUIDToString(IDispatcher);
        if (appDispatcher = nil) and (not appContainer.has(dispatcherId)) then
        begin
            appContainer.add(
                dispatcherId,
                TSimpleDispatcherFactory.create(
                    appContainer.get(routerId) as IRouteMatcher,
                    TRequestResponseFactory.create()
                )
            );
        end;

        inherited create(
            appContainer,
            appErr,
            appDispatcher,
            workerServer,
            appProcessor,
            appOutputBuffer,
            appStdOutWriter,
            appStdIn
        );
    end;

    function TBaseSimpleScgiWebApplication.initDispatcher(const container : IDependencyContainer) : IDispatcher;
    begin
        result := container.get(GUIDToString(IDispatcher)) as IDispatcher;
    end;
end.
