import { GoogleGenAI } from "@google/genai";

const getAiClient = () => {
  const apiKey = process.env.API_KEY;
  if (!apiKey) {
    throw new Error("API Key not found");
  }
  return new GoogleGenAI({ apiKey });
};

export const generateCardDescription = async (title: string, currentContext: string, language: string): Promise<string> => {
  try {
    const ai = getAiClient();
    const langInstruction = language === 'pt' 
      ? "Answer in Portuguese (Brazil)." 
      : "Answer in English.";
      
    const prompt = `
      ${langInstruction}
      Write a professional and concise description for a project task card titled: "${title}".
      Context provided: "${currentContext}".
      The description should include a brief objective, potential acceptance criteria, and suggested next steps.
      Format the output in Markdown.
    `;

    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: prompt,
    });

    return response.text || "Could not generate description.";
  } catch (error) {
    console.error("Gemini API Error:", error);
    return "Error generating content. Please check your API key.";
  }
};
