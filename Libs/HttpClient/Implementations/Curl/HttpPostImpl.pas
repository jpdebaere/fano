{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit HttpPostImpl;

interface

{$MODE OBJFPC}
{$H+}

uses

    HttpMethodImpl,
    ResponseIntf,
    SerializeableIntf;

type

    (*!------------------------------------------------
     * class that send HTTP POST to server
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    THttpPost = class(THttpMethod)
    public

        (*!------------------------------------------------
         * send HTTP request
         *-----------------------------------------------
         * @param url url to send request
         * @param context object instance related to this message
         * @return response from server
         *-----------------------------------------------*)
        function send(
            const url : string;
            const context : ISerializeable = nil
        ) : IResponse;

    end;

implementation

uses

    libcurl;

    (*!------------------------------------------------
     * send HTTP request
     *-----------------------------------------------
     * @param url url to send request
     * @param data data related to this request
     * @return current instance
     *-----------------------------------------------*)
    function THttpPost.send(
        const url : string;
        const data : ISerializeable = nil
    ) : IResponse;
    var hCurl : pCurl;
        params : string;
    begin
        hCurl:= curl_easy_init();
        if assigned(hCurl) then
        begin
            try
                curl_easy_setopt(hCurl,CURLOPT_URL, [url]);
                if (data <> nil) then
                begin
                    params := data.serialize();
                    curl_easy_setopt(hCurl,CURLOPT_POSTFIELDS, [ params ]);
                end;
                executeCurl(hCurl);
            finally
                //wrap with finally to make sure cleanup is done properly
                curl_easy_cleanup(hCurl);
            end;
        end;
        result := self;
    end;

end.
