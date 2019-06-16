{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}
unit FcgiProcessorImpl;

interface

{$MODE OBJFPC}
{$H+}

uses

    Classes,
    EnvironmentIntf,
    StreamAdapterIntf,
    FcgiProcessorIntf,
    FcgiRequestManagerIntf,
    FcgiFrameParserIntf;

type

    (*!-----------------------------------------------
     * FastCGI frame processor that parse FastCGI frame
     * and build CGI environment and write response
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    TFcgiProcessor = class(TInterfacedObject, IFcgiProcessor)
    private
        fcgiParser : IFcgiFrameParser;
        fcgiRequestMgr : IFcgiRequestManager;

        //store request id that is complete
        fcgiRequestId : word;

        tmpBuffer : TMemoryStream;

        function processBuffer(const buffer : pointer; const bufferSize : int64; out totRead : int64) : boolean;
        function discardReadData(const tmp : TMemoryStream; const bytesToDiscard : int64) : TMemoryStream;
    public
        (*!-----------------------------------------------
         * constructor
         *------------------------------------------------
         * @param parser FastCGI frame parser
         * @param requestMgr, instance of request manager
         *-----------------------------------------------*)
        constructor create(
            const parser : IFcgiFrameParser;
            const requestMgr : IFcgiRequestManager
        );

        destructor destroy(); override;

        (*!------------------------------------------------
         * process request stream
         *-----------------------------------------------
         * @return true if all data from web server is ready to
         * be handle by application (i.e, environment, STDIN already parsed)
         *-----------------------------------------------*)
        function process(const stream : IStreamAdapter) : boolean;

        (*!------------------------------------------------
         * get current environment
         *-----------------------------------------------
         * @return environment
         *-----------------------------------------------*)
        function getEnvironment() : ICGIEnvironment;

        (*!------------------------------------------------
         * get request id that is complete
         *-----------------------------------------------
         * @return request id
         *-----------------------------------------------*)
        function getRequestId() : word;
    end;

implementation

uses

    fastcgi,
    sysutils,
    math,
    FcgiEnvironmentImpl,
    FcgiRecordIntf,
    KeyValuePairIntf,
    EnvironmentFactoryIntf,
    EInvalidFcgiRequestIdImpl;

    (*!-----------------------------------------------
     * constructor
     *------------------------------------------------
     * @param parser FastCGI frame parser
     * @param requestMgr, instance of request manager
     *-----------------------------------------------*)
    constructor TFcgiProcessor.create(
        const parser : IFcgiFrameParser;
        const requestMgr : IFcgiRequestManager
    );
    begin
        inherited create();
        fcgiParser := parser;
        fcgiRequestMgr := requestMgr;
        fcgiRequestId := 0;
        tmpBuffer := TMemoryStream.create();
    end;

    (*!-----------------------------------------------
     * destructor
     *-----------------------------------------------*)
    destructor TFcgiProcessor.destroy();
    begin
        inherited destroy();
        fcgiParser := nil;
        fcgiRequestMgr := nil;
        freeAndNil(tmpBuffer);
    end;

    (*!-----------------------------------------------
     * parse stream for FCGI records
     *------------------------------------------------
     * @param buffer, buffer where data from socket is stored
     * @param bufferSize, size of buffer where data from socket is stored
     * @return boolean true when FCGI_PARAMS and FCGI_STDIN
     *         stream is complete otherwise false
     *-----------------------------------------------*)
    function TFcgiProcessor.processBuffer(const buffer : pointer; const bufferSize : int64; out totRead : int64) : boolean;
    var arecord : IFcgiRecord;
        complete : boolean;
    begin
        complete := false;
        totRead := 0;
        if (fcgiParser.hasFrame(buffer, bufferSize)) then
        begin
            arecord := fcgiParser.parseFrame(buffer, bufferSize);
            totRead := arecord.getRecordSize();
            complete := fcgiRequestMgr.add(arecord).complete(arecord.getRequestId());
            if (complete) then
            begin
                //request is complete, keep track request id that is complete
                fcgiRequestId := arecord.getRequestId();
                //TODO : initialize CGI environment for this request
                //TODO : initialize POST-ed for this request
            end;
        end;

        result := complete;
    end;

    function TFcgiProcessor.discardReadData(const tmp : TMemoryStream; const bytesToDiscard : int64) : TMemoryStream;
    var tmpReadBuffer : TMemoryStream;
    begin
        //discard read buffer
        tmpReadBuffer := TMemoryStream.create();
        try
            tmp.seek(bytesToDiscard, soFromBeginning);
            tmpReadBuffer.copyFrom(tmp, tmp.size - bytesToDiscard);
        finally
            tmp.free();
            result := tmpReadBuffer;
        end;
    end;

    (*!-----------------------------------------------
     * parse stream for FCGI records
     *------------------------------------------------
     * @param stream socket stream
     * @return boolean true when FCGI_PARAMS and FCGI_STDIN
     *         stream is complete otherwise false
     *-----------------------------------------------*)
    function TFcgiProcessor.process(const stream : IStreamAdapter) : boolean;
    var tmp : pointer;
        tmpSize, totRead : int64;
    begin
        tmpSize := stream.size();
        getMem(tmp, tmpSize);
        try
            stream.readBuffer(tmp^, tmpSize);
            tmpBuffer.writeBuffer(tmp^, tmpSize);
            result := processBuffer(tmpBuffer.memory, tmpBuffer.size, totRead);
            if (totRead > 0) then
            begin
                tmpBuffer := discardReadData(tmpBuffer, totRead);
            end;
        finally
            freeMem(tmp, tmpSize);
        end;
    end;

    (*!------------------------------------------------
     * get current environment
     *-----------------------------------------------
     * @return environment
     *-----------------------------------------------*)
    function TFcgiProcessor.getEnvironment() : ICGIEnvironment;
    var paramStream : IStreamAdapter;
        factory : ICGIEnvironmentFactory;
    begin
        paramStream := fcgiRequestMgr.getParamsStream(fcgiRequestId);
        factory := TFCGIEnvironmentFactory.create(paramStream);
        result := factory.build();
    end;

    (*!------------------------------------------------
     * get request id that is complete
     *-----------------------------------------------
     * @return request id
     *-----------------------------------------------*)
    function TFcgiProcessor.getRequestId() : word;
    begin
        result := fcgiRequestId;
    end;

end.
