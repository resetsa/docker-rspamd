package rspam

import (
	"crypto/tls"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"time"

	"github.com/go-resty/resty/v2"
)

const (
	connTimeout = 5 * time.Second
)

type RspamSender struct {
	client *resty.Client
	req    *resty.Request
	resp   *resty.Response
	answer RspamResponse
}

func New(url string, timeout time.Duration) *RspamSender {
	// set timeout for TCP connection
	c := &http.Client{
		Transport: &http.Transport{
			Dial: (&net.Dialer{
				Timeout:   connTimeout,
				KeepAlive: 30 * time.Second,
			}).Dial,
			TLSHandshakeTimeout: connTimeout,
		},
	}
	client := resty.NewWithClient(c)
	// set timeout for all request
	client.SetTimeout(timeout)
	client.SetBaseURL(url)
	client.SetTLSClientConfig(&tls.Config{InsecureSkipVerify: true})
	return &RspamSender{client: client}
}

func (r *RspamSender) GenerateReq(file io.Reader) {
	r.req = r.client.R().SetBody(file)
	r.req.SetHeader("Content-Type", "multipart/form-data")
	r.req.Method = "POST"
	r.req.URL = "/checkv2"
}

func (r *RspamSender) SetID(id string) {
	r.req.SetHeader("Queue-Id", id)
}

func (r *RspamSender) SendReq() (err error) {
	r.resp, err = r.req.Send()
	return err
}

func (r *RspamSender) ParseAnswer() error {
	return json.Unmarshal(r.resp.Body(), &r.answer)
}

func (r *RspamSender) Answer() RspamResponse {
	return r.answer
}
