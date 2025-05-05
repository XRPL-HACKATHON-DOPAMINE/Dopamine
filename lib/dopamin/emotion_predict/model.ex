defmodule EmotionPredict.Model do
  @hf_model_repo "alsgyu/sentiment-analysis-fine-tuned-model"
  @hf_tokenizer_repo "klue/bert-base"

  defp load() do
    {:ok, model_info} =
      Bumblebee.load_model({:hf, @hf_model_repo}, architecture: :for_sequence_classification)

    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, @hf_tokenizer_repo})
    {model_info, tokenizer}
  end

  def serving(opts \\ []) do
    opts =
      Keyword.validate!(opts, [
        :defn_options,
        sequence_length: 100,
        batch_size: 16
      ])

    {model_info, tokenizer} = load()

    Bumblebee.Text.text_classification(model_info, tokenizer,
      defn_options: opts[:defn_options],
      compile: [
        sequence_length: opts[:sequence_length],
        batch_size: opts[:batch_size]
      ]
    )
  end

  def predict(text) do
    Nx.Serving.batched_run(EmotionPredictModel, text)
  end
end
