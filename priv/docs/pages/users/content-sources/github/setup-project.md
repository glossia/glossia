# Configure the project

When you set up a project on Glossia and link it to a GitHub repository, you grant Glossia the authority to detect content alterations and save the localizations. Yet, this alone isn't enough. Certain modifications and files in the repository are essential for this integration to function seamlessly.

> #### Automatic configuration
> In the future, we aim to fully automate the project onboarding process.


## Extract the content

To begin, you'll need to extract the content from the source code. The format doesn't matter as long as it's supported by the LLM. Some of the compatible formats include [YAML](https://en.wikipedia.org/wiki/YAML), [JSON](https://en.wikipedia.org/wiki/JSON), [Portable Objects](https://en.wikipedia.org/wiki/Portable_object_(computing)), [Property Lists](https://en.wikipedia.org/wiki/Property_list), [String Resources](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/LoadingResources/Strings/Strings.html), and so on.

**We advise using the format recommended for the technology you've chosen.** This approach ensures you tap into a broader community and avail yourself of more resources, facilitating the loading and manipulation of those files in your code.

Initially, we suggest extracting only a subset of the content. This allows you to confirm that Glossia's continuous localization workflow operates as anticipated.

## Add a configuration file

Glossia utilizes the `glossia.jsonc` configuration files, which can be placed either at the root or within any nested directory. These files specify the content's location, the source and target languages, and provide context specific to the repository to steer the localization process. As a starting point, we suggest placing a `glossia.jsonc` file at your repository's root, populated with the following content:

```jsonc
{
  "$schema": "https://glossia.ai/schemas/configuration.json",
  "context": {
    "source": {
      "description": "It refers to a web app that provides localization workflows to organizations",
      "language": "en"
    },
    "target": [
      {
        "language": "de"
      },
      {
        "language": "es"
      }
    ]
  },
  
  "files": "src/**/{language}.json"
}
```

Adjust `context.source.description` to reflect the content's purpose. The `context.source.language` field specifies the language of the source content. The `context.target` array enumerates the target languages. The `files` field specifies the location of the content files. The `{language}` placeholder is replaced with the target language code.

> #### Schema
> While we work on providing comprehensive formatted documentation, you can consult the [configuration schema](https://glossia.ai/schemas/configuration.json) for a detailed understanding of all the configuration possibilities.

## Push the configuration upstream

After finalizing the configuration, push it upstream. Upon detecting the configuration file, Glossia activates continuous localization. To support incremental localizations, Glossia generates **lockfiles** in the repository, saving both time and money. Given that incremental detection occurs at the file level, we advise against using a monolithic content file. Instead, it's beneficial to modularize content in a manner similar to componentizing UI elements, positioning it as close to the UI as feasible. Dive deeper into [this approach](https://community.glossia.ai/t/configuration-of-software-projects/14) to grasp the rationale behind our recommendation.

> #### Modularization and coherence
> One challenge when modularizing content alongside LLMs is maintaining consistent localizations across various content pieces and sources. We're actively addressing this by developing tools designed to capture and utilize context, whether implicit or explicit.