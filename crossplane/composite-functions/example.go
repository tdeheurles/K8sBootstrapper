package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"

	"gopkg.in/yaml.v2"
)

const (
	AnnotationKeyAuthor = "quotable.io/author"
	AnnotationKeyQuote  = "quotable.io/quote"
)

type Quote struct {
	Author  string `json:"author"`
	Content string `json:"content"`
}

type FunctionIO struct {
	Desired *Desired `yaml:"desired"`
	Results []Result `yaml:"results"`
}

type Desired struct {
	Resources []Resource `yaml:"resources"`
}

type Resource struct {
	Name     string        `yaml:"name"`
	Resource *MetaResource `yaml:"resource"`
}

type MetaResource struct {
	Metadata *Metadata `yaml:"metadata"`
}

type Metadata struct {
	Annotations map[string]string `yaml:"annotations"`
}

type Result struct {
	Severity string `yaml:"severity"`
	Message  string `yaml:"message"`
}

func getQuote() (string, string, error) {
	resp, err := http.Get("https://api.quotable.io/random")
	if err != nil {
		return "", "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", "", fmt.Errorf("unexpected status code: %v", resp.StatusCode)
	}

	decoder := json.NewDecoder(resp.Body)
	var quote Quote
	err = decoder.Decode(&quote)
	if err != nil {
		return "", "", err
	}

	return quote.Author, quote.Content, nil
}

func readFunctionIO() (*FunctionIO, error) {
	data, err := ioutil.ReadAll(os.Stdin)
	if err != nil {
		return nil, err
	}

	var functionIO FunctionIO
	err = yaml.Unmarshal(data, &functionIO)
	if err != nil {
		return nil, err
	}

	return &functionIO, nil
}

func writeFunctionIO(functionIO *FunctionIO) {
	data, err := yaml.Marshal(functionIO)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	fmt.Print(string(data))
	os.Exit(0)
}

func resultWarning(functionIO *FunctionIO, message string) {
	functionIO.Results = append(functionIO.Results, Result{
		Severity: "Warning",
		Message:  message,
	})
}

func main() {
	functionIO, err := readFunctionIO()
	if err != nil {
		fmt.Fprintf(os.Stderr, "cannot parse FunctionIO: %v\n", err)
		os.Exit(1)
	}

	// Handle the case where we have to CREATE the resource as it doesn't exist yet
	if functionIO.Desired == nil || functionIO.Desired.Resources == nil {
		writeFunctionIO(functionIO)
	}

	quote, author, err := getQuote()
	if err != nil {
		resultWarning(functionIO, fmt.Sprintf("Cannot get quote: %v", err))
		writeFunctionIO(functionIO)
	}

	// Handle the case where we have to UPDATE the resource as it already exists
	for i := range functionIO.Desired.Resources {
		resource := &functionIO.Desired.Resources[i]
		if resource.Resource == nil {
			resultWarning(functionIO, fmt.Sprintf("Desired resource %s missing resource body", resource.Name))
			continue
		}

		if resource.Resource.Metadata == nil {
			resource.Resource.Metadata = &Metadata{}
		}

		if resource.Resource.Metadata.Annotations == nil {
			resource.Resource.Metadata.Annotations = make(map[string]string)
		}

		if _, ok := resource.Resource.Metadata.Annotations[AnnotationKeyQuote]; ok {
			continue
		}

		resource.Resource.Metadata.Annotations[AnnotationKeyAuthor] = author
		resource.Resource.Metadata.Annotations[AnnotationKeyQuote] = quote
	}

	writeFunctionIO(functionIO)
}
